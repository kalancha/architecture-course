import { FastifyInstance } from 'fastify';
import { buildTemperatureResponse } from '../utils/temperature';

export function registerTemperatureRoutes(fastify: FastifyInstance) {
  fastify.get('/temperature', (request, reply) => {
    const query = request.query as {
      location?: string;
    };

    const resp = buildTemperatureResponse({
      location: query.location,
    });

    reply.send(resp);
  });

  fastify.get('/temperature/:deviceId', (request, reply) => {
    const params = request.params as { deviceId?: string };
    const query = request.query as { location?: string };

    const resp = buildTemperatureResponse({
      location: query.location,
      sensorId: params.deviceId,
    });

    reply.send(resp);
  });
}
