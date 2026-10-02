import '../domain/models/weekly_doc.dart';

/// Template tên hiển thị.
class DocTemplate {
  final String id;
  final String label;
  final String description;
  final String defaultSkill;

  const DocTemplate({
    required this.id,
    required this.label,
    required this.description,
    required this.defaultSkill,
  });
}

/// Danh sách template có sẵn.
const List<DocTemplate> docTemplates = [
  DocTemplate(
    id: 'reading-lesson',
    label: 'Reading Lesson',
    description: 'Passage + câu hỏi + từ vựng',
    defaultSkill: 'Reading',
  ),
  DocTemplate(
    id: 'listening-lesson',
    label: 'Listening Lesson',
    description: 'Script + quiz + vocab',
    defaultSkill: 'Listening',
  ),
  DocTemplate(
    id: 'writing-task',
    label: 'Writing Task',
    description: 'Yêu cầu + mẫu + tips',
    defaultSkill: 'Writing',
  ),
  DocTemplate(
    id: 'speaking-cue',
    label: 'Speaking Cue Card',
    description: 'Cue card + cấu trúc + từ vựng',
    defaultSkill: 'Speaking',
  ),
  DocTemplate(
    id: 'vocabulary-set',
    label: 'Vocabulary Set',
    description: 'Bộ từ vựng + quiz + pattern',
    defaultSkill: 'Vocabulary',
  ),
  DocTemplate(
    id: 'blank',
    label: 'Trống',
    description: 'Tự xây từ đầu',
    defaultSkill: 'Reading',
  ),
];

/// Tạo WeeklyDoc khung từ template.
WeeklyDoc buildTemplateDoc({
  required String id,
  required String title,
  required int week,
  required int order,
  required String skill,
  required String templateId,
}) {
  final meta = DocMeta(
    title: title,
    week: week,
    order: order,
    skills: [skill],
    status: DocStatus.draft,
    defaultView: DocViewMode.doc,
    allowedViews: [DocViewMode.doc, DocViewMode.slide],
    allowUserSwitchView: true,
  );

  final sections = switch (templateId) {
    'reading-lesson' => [
        DocSection(
          number: 1,
          title: 'Introduction',
          blocks: [
            DocBlock.paragraph(
              text: 'Introduce the passage topic and exam context.',
            ),
            DocBlock.callout(
              text: '**Strategy:** Read the questions first, then scan for keywords.',
            ),
          ],
        ),
        DocSection(
          number: 2,
          title: 'Passage',
          blocks: [
            DocBlock.passage(
              label: 'Passage title',
              text: 'Paste or write the reading passage here.',
            ),
            DocBlock.slideBreak(),
          ],
        ),
        DocSection(
          number: 3,
          title: 'Questions',
          blocks: [
            DocBlock.quiz(
              question: 'Sample question',
              options: ['Option A', 'Option B', 'Option C', 'Option D'],
              correctIndex: 0,
              explanation: 'Explanation here.',
            ),
            DocBlock.vocab(
              items: [
                VocabItem(word: 'example', meaning: 'từ mẫu'),
              ],
            ),
          ],
        ),
      ],
    'listening-lesson' => [
        DocSection(
          number: 1,
          title: 'Warm-up',
          blocks: [
            DocBlock.heading(text: 'Listening Section'),
            DocBlock.paragraph(
              text: 'Instructions for the listening task.',
            ),
            DocBlock.callout(
              text: '**Tip:** Focus on intonation and rephrasing.',
            ),
          ],
        ),
        DocSection(
          number: 2,
          title: 'Script & Practice',
          blocks: [
            DocBlock.passage(
              label: 'Recording Script',
              text: 'Paste the transcript here for review.',
            ),
            DocBlock.quiz(
              question: 'What does the speaker mean?',
              options: ['A', 'B', 'C', 'D'],
              correctIndex: 1,
              explanation: 'The key phrase indicates option B.',
            ),
            DocBlock.slideBreak(),
          ],
        ),
        DocSection(
          number: 3,
          title: 'Vocabulary',
          blocks: [
            DocBlock.vocab(
              items: [
                VocabItem(word: 'affordable', partOfSpeech: 'adj', meaning: 'vừa túi tiền'),
                VocabItem(word: 'accommodation', partOfSpeech: 'n', meaning: 'chỗ ở'),
              ],
            ),
            DocBlock.steps(
              items: [
                '1. Listen first pass',
                '2. Check answers',
                '3. Review vocab',
              ],
            ),
          ],
        ),
      ],
    'writing-task' => [
        DocSection(
          number: 1,
          title: 'Task',
          blocks: [
            DocBlock.callout(
              text: 'You should spend about 20 minutes on this task.',
            ),
            DocBlock.passage(
              label: 'Task requirement',
              text: 'Write at least 250 words. Describe / discuss / argue…',
            ),
          ],
        ),
        DocSection(
          number: 2,
          title: 'Useful Structures',
          blocks: [
            DocBlock.steps(
              items: [
                'Introduction — "It is often argued that…"',
                'Body 1 — "On the one hand, …"',
                'Body 2 — "On the other hand, …"',
                'Conclusion — "In conclusion, …"',
              ],
            ),
            DocBlock.pattern(
              text: 'Although + clause, subject + verb',
            ),
          ],
        ),
        DocSection(
          number: 3,
          title: 'Sample & Vocab',
          blocks: [
            DocBlock.passage(
              label: 'Sample answer (Band 8)',
              text: 'Paste a sample answer here.',
            ),
            DocBlock.vocab(
              items: [
                VocabItem(word: 'compelling', partOfSpeech: 'adj', meaning: 'thuyết phục'),
                VocabItem(word: 'albeit', partOfSpeech: 'conj', meaning: 'mặc dù'),
              ],
            ),
          ],
        ),
      ],
    'speaking-cue' => [
        DocSection(
          number: 1,
          title: 'Cue Card',
          blocks: [
            DocBlock.callout(
              text: 'You have **1 minute** to prepare and **2 minutes** to speak.',
            ),
            DocBlock.passage(
              label: 'Describe…',
              text: 'You should say:\n- What…\n- When…\n- Why…',
            ),
          ],
        ),
        DocSection(
          number: 2,
          title: 'Useful Structures',
          blocks: [
            DocBlock.steps(
              items: [
                'Opening — "I\'d like to talk about…"',
                'Detail — "What struck me most was…"',
                'Closing — "Overall, it was…"',
              ],
            ),
            DocBlock.vocab(
              items: [
                VocabItem(word: 'thought-provoking', partOfSpeech: 'adj', meaning: 'gợi suy nghĩ'),
                VocabItem(word: 'struck me', partOfSpeech: 'v (past)', meaning: 'gây ấn tượng'),
              ],
            ),
          ],
        ),
      ],
    'vocabulary-set' => [
        DocSection(
          number: 1,
          title: 'Vocabulary',
          blocks: [
            DocBlock.paragraph(
              text: 'A set of related words and phrases.',
            ),
            DocBlock.vocab(
              items: [
                VocabItem(word: 'word1', partOfSpeech: 'n', ipa: '/wɜːd/', meaning: 'nghĩa'),
                VocabItem(word: 'word2', partOfSpeech: 'adj', ipa: '/wɜːd/', meaning: 'nghĩa'),
                VocabItem(word: 'word3', partOfSpeech: 'v', ipa: '/wɜːd/', meaning: 'nghĩa'),
              ],
            ),
          ],
        ),
        DocSection(
          number: 2,
          title: 'Practice',
          blocks: [
            DocBlock.quiz(
              question: 'Choose the correct meaning',
              options: ['A', 'B', 'C', 'D'],
              correctIndex: 0,
              explanation: 'Explanation',
            ),
            DocBlock.pattern(
              text: 'collocation / sentence pattern',
            ),
          ],
        ),
      ],
    _ => [
        DocSection(
          number: 1,
          title: 'Section 1',
          blocks: [
            DocBlock.paragraph(text: 'Start writing here…'),
          ],
        ),
      ],
  };

  return WeeklyDoc(id: id, meta: meta, sections: sections);
}
