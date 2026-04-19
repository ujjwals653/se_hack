import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { execSync } from 'child_process';
import * as fs from 'fs';
import * as path from 'path';
import * as os from 'os';

admin.initializeApp();

export const compileLatexOnPush = functions
  .runWith({ memory: '1GB', timeoutSeconds: 300 })
  .https.onRequest(async (req, res) => {

    // 1. Verify it's a GitHub push event
    const event = req.headers['x-github-event'];
    if (event !== 'push') { res.status(200).send('ignored'); return; }

    const { repository, ref } = req.body;
    if (ref !== 'refs/heads/main') { res.status(200).send('not main'); return; }

    const repoUrl   = repository.clone_url;
    const repoName  = repository.name;          // e.g. "lab-report"
    const commitSha = req.body.after.slice(0, 7);

    const tmpDir = fs.mkdtempSync(path.join(os.tmpdir(), 'latex-'));

    try {
      // 2. Clone the repo
      execSync(`git clone --depth 1 ${repoUrl} ${tmpDir}`, { stdio: 'pipe' });

      // 3. Compile with tectonic (pre-bundled in the function image)
      //    tectonic auto-downloads packages on first run, caches them
      execSync(`tectonic ${tmpDir}/main.tex --outdir ${tmpDir}`, {
        stdio: 'pipe',
        env: { ...process.env, TECTONIC_CACHE_DIR: '/tmp/tectonic-cache' }
      });

      const pdfPath = path.join(tmpDir, 'main.pdf');
      if (!fs.existsSync(pdfPath)) throw new Error('PDF not generated');

      // 4. Upload to Cloud Storage
      const bucket   = admin.storage().bucket();
      const destPath = `lab-reports/${repoName}/latest.pdf`;
      await bucket.upload(pdfPath, {
        destination: destPath,
        metadata: { contentType: 'application/pdf' },
      });

      // 5. Generate a signed URL (valid 7 days — refresh on next compile)
      const [signedUrl] = await bucket.file(destPath).getSignedUrl({
        action:  'read',
        expires: Date.now() + 7 * 24 * 60 * 60 * 1000,
      });

      // 6. Write metadata to Firestore — Flutter listens to this doc
      await admin.firestore()
        .collection('lab_reports')
        .doc(repoName)
        .set({
          pdfUrl:      signedUrl,
          commitSha,
          compiledAt:  admin.firestore.FieldValue.serverTimestamp(),
          status:      'success',
          repoName,
        });

      res.status(200).send('compiled ok');

    } catch (err: any) {
      // Write error state so Flutter can show it
      await admin.firestore()
        .collection('lab_reports')
        .doc(repoName)
        .set({
          status:     'error',
          error:      err.message,
          compiledAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });

      res.status(500).send('compile failed');
    } finally {
      fs.rmSync(tmpDir, { recursive: true, force: true });
    }
  });
