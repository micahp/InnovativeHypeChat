const nock = require('nock');
const togetherRequest = require('../providers/TogetherProvider');

describe('TogetherProvider embeddings', () => {
  it('should return embedding length > 0', async () => {
    const scope = nock('https://api.together.xyz')
      .post('/v1/embeddings')
      .reply(200, { data: [{ embedding: [0.1, 0.2, 0.3] }] });

    const result = await togetherRequest('embeddings', {
      model: 'test-model',
      input: ['hello'],
    });
    expect(result.data[0].embedding.length).toBeGreaterThan(0);
    scope.done();
  });

  it('handles API errors', async () => {
    nock('https://api.together.xyz').post('/v1/embeddings').reply(500);
    await expect(
      togetherRequest('embeddings', { model: 'm', input: ['x'] })
    ).rejects.toThrow('embeddings 500');
  });
});
