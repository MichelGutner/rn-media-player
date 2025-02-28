import type { VideoPlayer } from './types';

const defaultSpeeds = [
  { name: '0.5x', value: 0.5 },
  { name: 'Normal', value: 1.0 },
  { name: '1.5x', value: 1.5 },
  { name: '2.0x', value: 2.0 },
];

export const setDefaultConfigs = (config: VideoPlayer) => {
  return {
    ...config,
    menuOptions: {
      captions: config?.menuOptions?.captions ?? {
        title: 'Subtitle',
        disabledCaptionName: 'Off',
        disabled: true,
      },
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
  tag: keyof Omit<VideoPlayer['menuOptions'], 'captions'>
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
    const initialOptionSelected = validIfOptionExists(optionSelected, options);
    const disabled = menus?.[tag]?.disabled || false;

    return {
      title,
      options,
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
