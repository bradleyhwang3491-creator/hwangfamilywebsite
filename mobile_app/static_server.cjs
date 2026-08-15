const http = require('http');
const fs = require('fs');
const path = require('path');

const root = path.join(__dirname, 'build', 'web');
const port = 5175;

const mimeTypes = {
  '.html': 'text/html',
  '.js': 'application/javascript',
  '.json': 'application/json',
  '.css': 'text/css',
  '.png': 'image/png',
  '.jpg': 'image/jpeg',
  '.svg': 'image/svg+xml',
  '.wasm': 'application/wasm',
  '.ico': 'image/x-icon',
  '.ttf': 'font/ttf',
  '.otf': 'font/otf',
};

http
  .createServer((req, res) => {
    let filePath = path.join(root, decodeURIComponent(req.url.split('?')[0]));
    if (req.url === '/' || !path.extname(filePath)) {
      filePath = path.join(root, 'index.html');
    }
    fs.readFile(filePath, (err, data) => {
      if (err) {
        res.writeHead(404);
        res.end('Not found');
        return;
      }
      const ext = path.extname(filePath);
      res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'application/octet-stream' });
      res.end(data);
    });
  })
  .listen(port, () => console.log(`Serving ${root} on http://localhost:${port}`));
