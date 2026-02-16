const express = require('express');
const path = require('path');

const app = express();
const port = process.env.PORT || 3000;

app.use(express.static(path.join(__dirname, 'public')));

app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.get('/api', (req, res) => {
  res.json({ message: 'Hello World changes'});
});

if (require.main === module) {
  // If the file is run directly, start the server
  const PORT = process.env.PORT || 3000;
  server = app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
}

module.exports = app