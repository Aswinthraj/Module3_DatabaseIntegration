use college_nosql;

db.createCollection("feedback");

db.feedback.insertMany([
  {
    student_id: 1,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 5,
    comments: "Excellent teaching. Would recommend.",
    tags: ["challenging", "well-structured", "good-examples"],
    submitted_at: new Date("2022-11-30T10:15:00Z"),
    attachments: [{ filename: "notes.pdf", size_kb: 240 }]
  },
  {
    student_id: 2,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 4,
    comments: "Good pace, tough assignments.",
    tags: ["challenging", "good-examples"],
    submitted_at: new Date("2022-11-28T09:00:00Z"),
    attachments: [{ filename: "summary.pdf", size_kb: 120 }]
  },
  {
    student_id: 5,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 2,
    comments: "Too fast-paced, hard to follow.",
    tags: ["challenging"],
    submitted_at: new Date("2022-12-01T14:30:00Z"),
    attachments: [{ filename: "feedback_notes.docx", size_kb: 50 }]
  },
  {
    student_id: 1,
    course_code: "CS102",
    semester: "2022-ODD",
    rating: 5,
    comments: "Clear explanations of normalisation and indexing.",
    tags: ["well-structured", "good-examples"],
    submitted_at: new Date("2022-11-25T11:00:00Z"),
    attachments: [{ filename: "db_notes.pdf", size_kb: 300 }]
  },
  {
    student_id: 5,
    course_code: "CS102",
    semester: "2022-ODD",
    rating: 4,
    comments: "Solid course overall.",
    tags: ["well-structured"],
    submitted_at: new Date("2022-11-26T16:45:00Z")
  },
  {
    student_id: 2,
    course_code: "CS103",
    semester: "2022-ODD",
    rating: 5,
    comments: "Loved the OOP project work.",
    tags: ["good-examples", "well-structured"],
    submitted_at: new Date("2022-11-29T13:20:00Z"),
    attachments: [{ filename: "project_notes.pdf", size_kb: 180 }]
  },
  {
    student_id: 3,
    course_code: "EC101",
    semester: "2021-ODD",
    rating: 3,
    comments: "Average, needs more practical labs.",
    tags: ["needs-improvement"],
    submitted_at: new Date("2021-11-20T10:00:00Z"),
    attachments: [{ filename: "lab_notes.pdf", size_kb: 90 }]
  },
  {
    student_id: 6,
    course_code: "EC101",
    semester: "2021-EVEN",
    rating: 2,
    comments: "Confusing circuit diagrams.",
    tags: ["needs-improvement", "challenging"],
    submitted_at: new Date("2021-05-15T09:30:00Z"),
    attachments: [{ filename: "diagram_issues.pdf", size_kb: 75 }]
  },
  {
    student_id: 4,
    course_code: "ME101",
    semester: "2023-ODD",
    rating: 4,
    comments: "Good real-world examples of thermodynamics.",
    tags: ["good-examples"],
    submitted_at: new Date("2023-11-18T12:00:00Z"),
    attachments: [{ filename: "thermo_notes.pdf", size_kb: 200 }]
  },
  {
    student_id: 7,
    course_code: "ME101",
    semester: "2021-EVEN",
    rating: 1,
    comments: "Did not enjoy this course.",
    tags: ["needs-improvement"],
    submitted_at: new Date("2021-05-10T08:45:00Z"),
    attachments: [{ filename: "complaint.pdf", size_kb: 30 }]
  },
  {
    student_id: 8,
    course_code: "CS101",
    semester: "2022-ODD",
    rating: 5,
    comments: "Best course this semester.",
    tags: ["challenging", "well-structured"],
    submitted_at: new Date("2022-12-02T17:10:00Z"),
    attachments: [{ filename: "praise_notes.pdf", size_kb: 60 }]
  }
]);

db.feedback.countDocuments();

db.feedback.find({ rating: 5 });

db.feedback.find({
  course_code: "CS101",
  tags: "challenging"
});

db.feedback.find(
  {},
  {
    student_id: 1,
    course_code: 1,
    rating: 1,
    _id: 0
  }
);

db.feedback.updateMany(
  { rating: { $lt: 3 } },
  { $set: { needs_review: true } }
);

db.feedback.updateMany(
  { needs_review: true },
  { $push: { tags: "reviewed" } }
);

db.feedback.deleteMany({
  semester: "2021-EVEN"
});

db.feedback.aggregate([
  {
    $match: {
      semester: "2022-ODD"
    }
  },
  {
    $group: {
      _id: "$course_code",
      avg_rating: { $avg: "$rating" },
      total_feedback: { $sum: 1 }
    }
  },
  {
    $sort: {
      avg_rating: -1
    }
  },
  {
    $project: {
      _id: 0,
      course_code: "$_id",
      average_rating: {
        $round: ["$avg_rating", 1]
      },
      total_feedback: 1
    }
  }
]);

db.feedback.aggregate([
  { $unwind: "$tags" },
  {
    $group: {
      _id: "$tags",
      count: { $sum: 1 }
    }
  },
  {
    $sort: {
      count: -1
    }
  }
]);

db.feedback.createIndex({ course_code: 1 });

db.feedback.find({ course_code: "CS101" }).explain("executionStats");