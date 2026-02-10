import { FastifyInstance } from 'fastify';

export function registerHealthRoutes(fastify: FastifyInstance) {
  fastify.get('/health', (_, reply) => {
    reply.send({ status: 'allgood' });
  });
}
