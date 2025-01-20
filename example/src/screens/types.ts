// Tipo para a fonte de um vídeo
interface VideoSource {
  type: string; // Tipo do vídeo (ex: "hls", "dash", "mp4")
  mime: string; // Tipo MIME (ex: "application/x-mpegurl")
  url: string; // URL da fonte
}

// Tipo para uma track (legenda ou outros dados)
interface VideoTrack {
  id: string; // ID da track
  type: string; // Tipo (ex: "text")
  subtype: string; // Subtipo (ex: "captions")
  contentId: string; // ID do conteúdo
  name: string; // Nome da track
  language: string; // Idioma (ex: "en-US")
}

// Tipo para cada vídeo na lista
interface Video {
  'subtitle': string; // Descrição do vídeo
  'sources': VideoSource[]; // Lista de fontes do vídeo
  'thumb': string; // Miniatura
  'image-480x270': string; // Imagem no formato 480x270
  'image-780x1200': string; // Imagem no formato 780x1200
  'title': string; // Título do vídeo
  'studio': string; // Estúdio/Produtor
  'duration': number; // Duração em segundos
  'tracks': VideoTrack[]; // Lista de tracks (legendas, etc.)
}

// Tipo para uma categoria
interface Category {
  name: string; // Nome da categoria (ex: "Movies")
  hls: string; // URL base para vídeos HLS
  dash: string; // URL base para vídeos Dash
  mp4: string; // URL base para vídeos MP4
  images: string; // URL base para imagens
  tracks: string; // URL base para tracks
  videos: Video[]; // Lista de vídeos na categoria
}

// Tipo raiz para o JSON completo
export interface Root {
  categories: Category[]; // Lista de categorias
}
