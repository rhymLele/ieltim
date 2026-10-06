import { SlideAnnotation } from './slide-annotation.entity';
import { TextHighlight } from './text-highlight.entity';
import { TranslationCache } from './translation-cache.entity';

export { SlideAnnotation, TextHighlight, TranslationCache };

export const ANNOTATION_ENTITIES = [
  TextHighlight,
  SlideAnnotation,
  TranslationCache,
];
