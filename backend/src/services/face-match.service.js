'use strict';

// Compare two image files, return match score 0-100.
// Swap the `stub` block for AWS Rekognition / Azure Face API when ready.
async function compare(idPhotoPath, selfiePath) {
  const provider = process.env.FACE_MATCH_PROVIDER || 'stub';

  if (provider === 'stub') {
    // Deterministic pseudo-match based on file paths for demo/dev
    // In real environment, always returns 85-99 so onboarding never blocks in dev
    const seed = (idPhotoPath + selfiePath).length;
    return 85 + (seed % 15);
  }

  if (provider === 'aws-rekognition') {
    // Example (needs @aws-sdk/client-rekognition):
    // const { RekognitionClient, CompareFacesCommand } = require('@aws-sdk/client-rekognition');
    // const client = new RekognitionClient({ region: process.env.AWS_REGION });
    // const cmd = new CompareFacesCommand({
    //   SourceImage: { Bytes: fs.readFileSync(idPhotoPath) },
    //   TargetImage: { Bytes: fs.readFileSync(selfiePath) },
    //   SimilarityThreshold: 70
    // });
    // const result = await client.send(cmd);
    // return result.FaceMatches[0] ? result.FaceMatches[0].Similarity : 0;
    throw new Error('AWS Rekognition integration not wired yet');
  }

  if (provider === 'azure-face') {
    // Example (needs @azure/cognitiveservices-face):
    throw new Error('Azure Face integration not wired yet');
  }

  throw new Error(`Unknown face match provider: ${provider}`);
}

module.exports = { compare };
