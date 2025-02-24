import type { VideoPlayer } from './types';

const defaultSpeeds = [
  { name: '0.5x', value: 0.5 },
  { name: 'Normal', value: 1.0 },
  { name: '1.5x', value: 1.5 },
  { name: '2.0x', value: 2.0 },
];

export const setDefaultConfigs = (config: VideoPlayer) => {
  const defaultCaptions = () => {
    if (!config?.menuOptions?.captions) {
      return config.menuOptions;
    }

    return {
      ...config?.menuOptions,
      captions: {
        ...config?.menuOptions?.captions,
        options: config?.menuOptions?.captions?.options
          .concat([
            {
              name: config?.menuOptions?.captions?.offOptionName || 'Off',
              value: 'off',
            },
          ])
          .sort((a, b) => (a.value === 'off' ? -1 : a.name > b.name ? 1 : -1)),
      },
    };
  };

  return {
    ...config,
    menuOptions: {
      captions: createOptions(defaultCaptions(), 'captions').builder({
        title: 'Captions',
        initialOptionSelected: 'Off',
      }),
      speeds: createOptions(config.menuOptions, 'speeds').builder({
        title: 'Playback Speed',
        options: defaultSpeeds,
        initialOptionSelected: 'Normal',
      }),
      qualities: createOptions(config.menuOptions, 'qualities').builder(),
    },
  };
};

const validIfOptionExists = (option: string | undefined, options: any[]) => {
  const exists = options?.some((opt) => opt.name === option);

  if (exists) {
    return option;
  } else {
    return options?.[0]?.name;
  }
};

const createOptions = (
  menus: VideoPlayer['menuOptions'],
  tag: keyof VideoPlayer['menuOptions']
) => {
  const builder = (defaultFields?: {
    title: string;
    options?: any[];
    initialOptionSelected?: string;
  }) => {
    const optionSelected =
      menus?.[tag]?.initialOptionSelected ||
      defaultFields?.initialOptionSelected;

    const options = menus?.[tag]?.options || defaultFields?.options;
    const title = menus?.[tag]?.title || defaultFields?.title;
    const offOptionName = menus?.[tag]?.offOptionName;
    const initialOptionSelected = validIfOptionExists(optionSelected, options);
    const disabled = menus?.[tag]?.disabled || false;

    return {
      title,
      options,
      offOptionName,
      initialOptionSelected,
      disabled,
    };
  };

  return { builder };
};

declare global {
  interface Array<T> {
    sort(compareFn?: (a: T, b: T) => number): this;
  }
}
