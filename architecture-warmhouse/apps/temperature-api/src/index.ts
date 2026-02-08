import Fastify from 'fastify';

const fastify = Fastify({ logger: true });

const start = async () => {
  try {
    const port = parseInt(process.env.PORT || '8081', 10);
    const host = process.env.HOST || '0.0.0.0';

    await fastify.listen({ port, host });
    fastify.log.info(`Temperature API server is running on http://${host}:${port}`);
  } catch (err) {
    fastify.log.error(err);
    process.exit(1);
  }
};

process.on('SIGTERM', async () => {
  fastify.log.info('SIGTERM signal received: closing HTTP server');
  await fastify.close();
  process.exit(0);
});

process.on('SIGINT', async () => {
  fastify.log.info('SIGINT signal received: closing HTTP server');
  await fastify.close();
  process.exit(0);
});

fastify.get('/health', (_, reply) => {
  reply.send({ status: 'allgood' });
});

fastify.get('/temperature', (request, reply) => {
  const temperature = Math.round((Math.random() / 2) * 100 - 25);
  reply.send({ temperature });
});

start();
