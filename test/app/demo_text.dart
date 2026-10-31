/// The demo data is Arabic. The English store screenshots switch
/// [demoEnglish] on so the same screens show English course names,
/// lessons and questions; every other test keeps the Arabic text.
bool demoEnglish = false;

String demo(String arabic) => demoEnglish ? (_en[arabic] ?? arabic) : arabic;

const _en = <String, String>{
  'التفاضل والتكامل': 'Calculus',
  'مقدمة عن النهايات': 'Introduction to limits',
  'النهايات': 'Limits',
  'النهايات بالتعويض المباشر': 'Limits by direct substitution',
  'النهايات من جهة واحدة': 'One-sided limits',
  'كويز النهايات': 'Limits quiz',
  'تعريف الاتصال': 'What continuity means',
  'الاتصال': 'Continuity',
  'أنواع عدم الاتصال': 'Types of discontinuity',
  'واجب الاتصال': 'Continuity assignment',
  'مراجعة ليلة الامتحان': 'Exam-eve review session',
  'مراجعة مباشرة يوم الخميس الساعة ٨ مساءً على المنهج كله. جهّز أسئلتك.': 'A live review of the whole syllabus on Thursday at 8 pm. Bring your questions.',
  'أ. أحمد سمير': 'Mr. Ahmed Samir',
  'الفيزياء: الكهربية': 'Physics: Electricity',
  'أ. منى عادل': 'Ms. Mona Adel',
  'الكيمياء العضوية': 'Organic Chemistry',
  'د. خالد فؤاد': 'Dr. Khaled Fouad',
  '<p>النهاية من اليمين هي القيمة التي تقترب منها الدالة عندما تقترب <b>س</b> من العدد من جهة اليمين.</p>': '<p>The right-hand limit is the value a function approaches as <b>x</b> approaches a number from the right.</p>',
  '<ul><li>نكتبها: نهـا س←أ⁺ د(س)</li><li>وتوجد النهاية إذا تساوت النهايتان من اليمين واليسار.</li></ul>': '<ul><li>Written as: lim x→a⁺ f(x)</li><li>The limit exists when the right- and left-hand limits are equal.</li></ul>',
  'ملخص الدرس (PDF)': 'Lesson summary (PDF)',
  'ما قيمة النهاية عندما تقترب س من ٢ للدالة د(س) = س² + ١؟':
      'What is the limit of f(x) = x² + 1 as x approaches 2?',
  '٣': '3',
  '٥': '5',
  'غير موجودة': 'Does not exist',
  'أي الدوال التالية متصلة عند س = ٠؟':
      'Which of these functions is continuous at x = 0?',
  'د(س) = س²': 'f(x) = x²',
  'د(س) = ١ ÷ س': 'f(x) = 1 ÷ x',
  'د(س) = |س|': 'f(x) = |x|',
  'اكتب اسم القاعدة المستخدمة في حالة ٠ ÷ ٠.':
      'Name the rule used for the 0 ÷ 0 case.',
  'اختبار الوحدة الأولى: النهايات': 'Unit 1 test: Limits',
  'ثلاثة أسئلة عن النهايات والاتصال. راجع درس «النهايات من جهة واحدة» قبل البدء.': 'Three questions on limits and continuity. Review “One-sided limits” before you start.',
  'نعوّض مباشرة: ٢² + ١ = ٥.': 'Substitute directly: 2² + 1 = 5.',
  'واجب: تمارين النهايات': 'Assignment: Limits practice',
  'حل التمارين من ١ إلى ٥ في الملزمة، ثم صوّر الحل وارفعه هنا. اكتب الناتج النهائي لكل تمرين في خانة الإجابة.': 'Solve exercises 1 to 5 in the workbook, then photograph your work and upload it here. Write each final answer in the answer box.',
  '١) ٥  ٢) ٠  ٣) غير موجودة  ٤) ٢  ٥) ١':
      '1) 5  2) 0  3) Does not exist  4) 2  5) 1',
  'حل ممتاز. راجع التمرين الثالث: النهاية موجودة من جهة اليمين فقط.': 'Excellent work. Look again at exercise 3: the limit exists from the right only.',
  'تقرير المعمل': 'Lab report',
  'مسائل الدوائر': 'Circuit problems',
  'اختبار الوحدة الأولى': 'Unit 1 test',
  'كويز المشتقات': 'Derivatives quiz',
  'كويز الروابط': 'Chemical bonds quiz',
  'واجب الحدود': 'Polynomials assignment',
  'التفاضل والتكامل: الصف الثالث الثانوي': 'Calculus: Grade 12',
  'اختبار قصير: الاتصال': 'Short quiz: Continuity',
  'واجب: رسم الدوال': 'Assignment: Graphing functions',
  'الفيزياء: الكهربية الحديثة': 'Physics: Modern Electricity',
  'زياد البدوي': 'Ziad Elbadawy',
};
