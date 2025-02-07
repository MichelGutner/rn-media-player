import type { VideoPlayer } from './types';

export const setDefaultConfigs = (config: VideoPlayer) => {
  const { menuOptions = {} } = config;

  return {
    ...config,
    menuOptions: {
      ...menuOptions,
      captions: {
        title: 'Captions',
        ...setEmptyObject(config.menuOptions?.captions),
        options: [
          {
            name: 'Off',
            value: 'off',
          },
          {
            name: 'Auto',
            value: 'auto',
          },
          ...setEmptyArray(config.menuOptions?.captions?.options),
        ],
        initialOptionSelected: 'Off',
      },
      speeds: {
        title: 'Playback Speed',
        options: [
          { name: '0.5x', value: 0.5 },
          { name: 'Normal', value: 1.0 },
          { name: '1.5x', value: 1.5 },
          { name: '2.0x', value: 2.0 },
          ...setEmptyArray(config.menuOptions?.speeds?.options),
        ],
        initialOptionSelected: 'Normal',
        disabled: false,
        ...setEmptyObject(config.menuOptions?.speeds),
      },
      qualities: setEmptyObject(config.menuOptions?.qualities),
    },
  };
};

const setEmptyObject = (obj: any) => {
  return obj ?? {};
};

const setEmptyArray = (arr?: any[]) => {
  return arr ?? [];
};
