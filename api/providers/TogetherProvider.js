const fetch = require('node-fetch');
const baseURL = 'https://api.together.xyz/v1';

module.exports = async function togetherRequest(route, body) {
  const res = await fetch(`${baseURL}/${route}`, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.TOGETHER_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error(`${route} ${res.status}`);
  return res.json();
};
