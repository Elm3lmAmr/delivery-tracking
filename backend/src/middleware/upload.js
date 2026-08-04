'use strict';

const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { v4: uuidv4 } = require('uuid');

const UPLOAD_DIR = process.env.UPLOAD_DIR || path.join(__dirname, '..', '..', 'uploads');
const MAX_SIZE_MB = parseInt(process.env.MAX_FILE_SIZE_MB, 10) || 8;

if (!fs.existsSync(UPLOAD_DIR)) {
  fs.mkdirSync(UPLOAD_DIR, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const sub = req.uploadSubfolder || 'misc';
    const dir = path.join(UPLOAD_DIR, sub);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    cb(null, dir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const safeExt = ['.jpg', '.jpeg', '.png', '.webp'].includes(ext) ? ext : '.jpg';
    cb(null, uuidv4() + safeExt);
  }
});

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp'];
  if (allowed.includes(file.mimetype)) cb(null, true);
  else cb(new Error('Only JPEG, PNG, or WebP images are allowed'), false);
};

const upload = multer({
  storage,
  fileFilter,
  limits: { fileSize: MAX_SIZE_MB * 1024 * 1024 }
});

function setSubfolder(sub) {
  return (req, res, next) => { req.uploadSubfolder = sub; next(); };
}

module.exports = { upload, setSubfolder };
