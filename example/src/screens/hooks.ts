import { useEffect, useState } from 'react';
import type { Root } from './types';

export const useFetch = (url: string) => {
  const [data, setData] = useState<Root>();

  useEffect(() => {
    const fetchData = async () => {
      const response = await fetch(url);
      const json = await response.json();
      setData(json);
    };
    fetchData().catch(console.error);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return { data };
};
