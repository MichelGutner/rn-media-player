import {
  download,
  completeHandler,
  directories,
} from '@kesha-antonov/react-native-background-downloader';

const jobId = 'file123';

export const downloadFile = (url: string) => {
  let task = download({
    id: jobId,
    url: url,
    destination: `${directories.documents}/file.mp4`,
    metadata: {},
  })
    .begin(({ expectedBytes, headers }) => {
      console.log(`Going to download ${expectedBytes} bytes!`);
    })
    .progress(({ bytesDownloaded, bytesTotal }) => {
      console.log(`Downloaded: ${(bytesDownloaded / bytesTotal) * 100}%`);
    })
    .done(({ bytesDownloaded, bytesTotal }) => {
      console.log('Download is done!', { bytesDownloaded, bytesTotal });

      // PROCESS YOUR STUFF

      // FINISH DOWNLOAD JOB
      completeHandler(jobId);
    })
    .error(({ error, errorCode }) => {
      console.log('Download canceled due to error: ', { error, errorCode });
    });
};
