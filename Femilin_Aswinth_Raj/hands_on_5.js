// ================================================================
// Digital Nurture 5.0 | Module 3: Database Integration
// HANDS-ON 5 [Intermediate] — MongoDB: Document Modelling, CRUD & Aggregation
// Student Course Registration System | mongosh
//
// Run with: mongosh < hands_on_5.js
// or paste sections interactively into mongosh / Compass's shell tab.
// ================================================================

// ----------------------------------------------------------------
// TASK 1: Create the Collection and Insert Documents
// ----------------------------------------------------------------

// Step 60: switch to (create) the college_nosql database
use college_nosql;

// Step 61: the feedback collection is created implicitly on first insert,
// but we can also create it explicitly:
db.createCollection("feedback");

// Step 62: insert at least 10 feedback documents
// (3+ for CS101, 2+ for CS102, varied ratings/tags/semesters)
db.feedback.insertMany([
  {
    student_id: 1,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 5,
    comments: "Excellent teaching. Would recommend.",
    tags: ["challenging", "well-structured", "good-examples"],
    submitted_at: new Date("2022-11-30T10:15:00Z"),
    attachments: [{ filename: "notes.pdf", size_kb: 240 }],
  },
  {
    student_id: 2,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 4,
    comments: "Good pace, tough assignments.",
    tags: ["challenging", "good-examples"],
    submitted_at: new Date("2022-11-28T09:00:00Z"),
    attachments: [{ filename: "summary.pdf", size_kb: 120 }],
  },
  {
    student_id: 5,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 2,
    comments: "Too fast-paced, hard to follow.",
    tags: ["challenging"],
    submitted_at: new Date("2022-12-01T14:30:00Z"),
    attachments: [{ filename: "feedback_notes.docx", size_kb: 50 }],
  },
  {
    student_id: 1,
    course_code: "CS102",
    semester: "2022-ODD",
    rating: 5,
    comments: "Clear explanations of normalisation and indexing.",
    tags: ["well-structured", "good-examples"],
    submitted_at: new Date("2022-11-25T11:00:00Z"),
    attachments: [{ filename: "db_notes.pdf", size_kb: 300 }],
  },
  {
    student_id: 5,
    course_code: "CS102",
    semester: "2022-ODD",
    rating: 4,
    comments: "Solid course overall.",
    tags: ["well-structured"],
    submitted_at: new Date("2022-11-26T16:45:00Z"),
    // intentionally no attachments field (see Step 63)
  },
  {
    student_id: 2,
    course_code: "CS103",
    semester: "2022-ODD",
    rating: 5,
    comments: "Loved the OOP project work.",
    tags: ["good-examples", "well-structured"],
    submitted_at: new Date("2022-11-29T13:20:00Z"),
    attachments: [{ filename: "project_notes.pdf", size_kb: 180 }],
  },
  {
    student_id: 3,
    course_code: "EC101",
    semester: "2021-ODD",
    rating: 3,
    comments: "Average, needs more practical labs.",
    tags: ["needs-improvement"],
    submitted_at: new Date("2021-11-20T10:00:00Z"),
    attachments: [{ filename: "lab_notes.pdf", size_kb: 90 }],
  },
  {
    student_id: 6,
    course_code: "EC101",
    semester: "2021-EVEN",
    rating: 2,
    comments: "Confusing circuit diagrams.",
    tags: ["needs-improvement", "challenging"],
    submitted_at: new Date("2021-05-15T09:30:00Z"),
    attachments: [{ filename: "diagram_issues.pdf", size_kb: 75 }],
  },
  {
    student_id: 4,
    course_code: "ME101",
    semester: "2023-ODD",
    rating: 4,
    comments: "Good real-world examples of thermodynamics.",
    tags: ["good-examples"],
    submitted_at: new Date("2023-11-18T12:00:00Z"),
    attachments: [{ filename: "thermo_notes.pdf", size_kb: 200 }],
  },
  {
    student_id: 7,
    course_code: "ME101",
    semester: "2021-EVEN",
    rating: 1,
    comments: "Did not enjoy this course.",
    tags: ["needs-improvement"],
    submitted_at: new Date("2021-05-10T08:45:00Z"),
    attachments: [{ filename: "complaint.pdf", size_kb: 30 }],
  },
  {
    student_id: 8,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 5,
    comments: "Best course this semester.",
    tags: ["challenging", "well-structured"],
    submitted_at: new Date("2022-12-02T17:10:00Z"),
    attachments: [{ filename: "praise_notes.pdf", size_kb: 60 }],
  },
]);

// Step 64: verify the inserts
db.feedback.countDocuments();
// Expected Outcome: 10 or more documents


// ----------------------------------------------------------------
// TASK 2: CRUD Operations
// ----------------------------------------------------------------

// Step 65: READ — all feedback documents where rating is 5
db.feedback.find({ rating: 5 });

// Step 66: READ — CS101 feedback where tags array contains 'challenging'
db.feedback.find({ course_code: "CS101", tags: "challenging" });
// Note: a simple value match against an array field (tags: "challenging")
// matches any document where 'challenging' is ONE of the array elements.
// $elemMatch would be needed only if we had multiple conditions on the
// SAME array element (e.g. an array of sub-documents with several
// fields that must all match together) — not needed here since tags
// is a flat array of strings.

// Step 67: READ — projection: student_id, course_code, rating only (exclude _id)
db.feedback.find({}, { student_id: 1, course_code: 1, rating: 1, _id: 0 });

// Step 68: UPDATE — add needs_review: true for all docs with rating < 3
db.feedback.updateMany(
  { rating: { $lt: 3 } },
  { $set: { needs_review: true } }
);

// Step 69: UPDATE — push 'reviewed' tag into tags array where needs_review is true
db.feedback.updateMany(
  { needs_review: true },
  { $push: { tags: "reviewed" } }
);

// Step 70: DELETE — remove all feedback where semester is '2021-EVEN'
db.feedback.deleteMany({ semester: "2021-EVEN" });


// ----------------------------------------------------------------
// TASK 3: Aggregation Pipeline
// ----------------------------------------------------------------

// Step 71 + 72: filter to 2022-ODD -> group by course_code with avg
// rating + count -> sort descending -> rename/round avg_rating
db.feedback.aggregate([
  { $match: { semester: "2022-ODD" } },
  {
    $group: {
      _id: "$course_code",
      avg_rating: { $avg: "$rating" },
      total_feedback: { $sum: 1 },
    },
  },
  { $sort: { avg_rating: -1 } },
  {
    $project: {
      _id: 0,
      course_code: "$_id",
      average_rating: { $round: ["$avg_rating", 1] },
      total_feedback: 1,
    },
  },
]);
// Expected Outcome: one document per course, average_rating rounded to 1 decimal

// Step 73: tag frequency leaderboard via $unwind + $group, sorted desc
db.feedback.aggregate([
  { $unwind: "$tags" },
  { $group: { _id: "$tags", count: { $sum: 1 } } },
  { $sort: { count: -1 } },
]);
// Expected Outcome: 'challenging' likely appears most frequently

// Step 74: index on course_code + verify usage with explain()
db.feedback.createIndex({ course_code: 1 });

db.feedback
  .find({ course_code: "CS101" })
  .explain("executionStats");
// Look for "stage": "IXSCAN" (not "COLLSCAN") in the
// executionStats.executionStages output to confirm the index is used.
