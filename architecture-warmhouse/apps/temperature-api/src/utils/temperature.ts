import { TemperatureResponse } from '../types/temperature';

export function resolveLocationAndsensorId(input: {
  location?: string;
  sensorId?: string;
}): { location: string; sensorId: string } {
  let location = (input.location ?? '').trim();
  let sensorId = (input.sensorId ?? '').trim();

  if (location === '') {
    switch (sensorId) {
      case '1':
        location = 'Living Room';
        break;
      case '2':
        location = 'Bedroom';
        break;
      case '3':
        location = 'Kitchen';
        break;
      default:
        location = 'Unknown';
        break;
    }
  }

  if (sensorId === '') {
    switch (location) {
      case 'Living Room':
        sensorId = '1';
        break;
      case 'Bedroom':
        sensorId = '2';
        break;
      case 'Kitchen':
        sensorId = '3';
        break;
      default:
        sensorId = '0';
        break;
    }
  }

  return { location, sensorId };
}

export function buildTemperatureResponse(input: {
  location?: string;
  sensorId?: string;
}): TemperatureResponse {
  const resolved = resolveLocationAndsensorId(input);

  const temperature = Math.round((Math.random() / 2) * 100 - 25);
  const timestamp = new Date().toISOString();

  const description =
    resolved.location === 'Unknown'
      ? 'Temperature reading from an unknown location'
      : `Temperature reading from ${resolved.location}`;

  return {
    value: temperature,
    unit: 'C',
    timestamp,
    location: resolved.location,
    status: 'ok',
    sensor_id: resolved.sensorId,
    sensor_type: 'temperature',
    description,
    temperature,
  };
}
