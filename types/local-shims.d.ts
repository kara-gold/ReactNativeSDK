declare module 'react-native-linear-gradient' {
  import type { ComponentType } from 'react';
  import type { ViewProps } from 'react-native';

  type LinearGradientProps = ViewProps & {
    angle?: number;
    colors: string[];
    end?: { x: number; y: number };
    start?: { x: number; y: number };
    useAngle?: boolean;
  };

  const LinearGradient: ComponentType<LinearGradientProps>;
  export default LinearGradient;
}

declare module 'fs' {
  const fs: {
    copyFileSync: (source: string, destination: string) => void;
    existsSync: (path: string) => boolean;
    mkdirSync: (
      path: string,
      options?: { recursive?: boolean }
    ) => unknown;
    readFileSync: (path: string, encoding: 'utf-8') => string;
    writeFileSync: (path: string, data: string, encoding?: 'utf-8') => void;
  };
  export = fs;
}

declare module 'path' {
  const path: {
    join: (...parts: string[]) => string;
  };
  export = path;
}

declare const __dirname: string;
