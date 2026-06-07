exports.handler = async function(event) {
  // CORS preflight
  if (event.httpMethod === 'OPTIONS') {
    return {
      statusCode: 204,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization'
      }
    };
  }

  if (event.httpMethod !== 'POST') {
    return { statusCode: 405, body: 'Method not allowed' };
  }

  try {
    // Parse the proxy request from the frontend
    const proxyReq = JSON.parse(event.body);
    const { url, headers: reqHeaders, body: reqBody } = proxyReq;

    console.log('Proxying to:', url);

    // Forward to the actual API
    const resp = await fetch(url, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': reqHeaders.Authorization || ''
      },
      body: JSON.stringify(reqBody)
    });

    // Read response as text first, then try JSON
    const text = await resp.text();
    let data;
    try {
      data = JSON.parse(text);
    } catch {
      // Response is not JSON (e.g. plain text error)
      data = { raw: text };
    }

    return {
      statusCode: resp.status,
      headers: {
        'Access-Control-Allow-Origin': '*',
        'Content-Type': 'application/json'
      },
      body: JSON.stringify(data)
    };
  } catch (err) {
    return {
      statusCode: 500,
      headers: { 'Access-Control-Allow-Origin': '*' },
      body: JSON.stringify({ error: err.message, stack: err.stack })
    };
  }
};
