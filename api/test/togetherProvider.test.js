const nock = require('nock');
const togetherRequest = require('../providers/TogetherProvider');

describe('TogetherProvider', () => {
  const base = 'https://api.together.xyz';

  afterEach(() => {
    nock.cleanAll();
  });

  it('sends auth header', async () => {
    const scope = nock(base, {
      reqheaders: {
        Authorization: 'Bearer test-key',
      },
    })
      .post('/v1/chat', { hello: 'world' })
      .reply(200, { ok: true });

    process.env.TOGETHER_API_KEY = 'test-key';
    const res = await togetherRequest('chat', { hello: 'world' });
    expect(res.ok).toBe(true);
    scope.done();
  });

  it('throws on http error', async () => {
    nock(base).post('/v1/chat').reply(500, { error: 'fail' });
    await expect(togetherRequest('chat', {})).rejects.toThrow('chat 500');
  });
});

