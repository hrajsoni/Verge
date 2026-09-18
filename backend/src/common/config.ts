import { ConfigService } from '@nestjs/config';

export function getEnvOrThrow(config: ConfigService, key: string): string {
  const val = config.get<string>(key);
  if (!val) throw new Error(`Missing env var: ${key}`);
  return val;
}
