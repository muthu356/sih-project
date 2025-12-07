1. High-Level Entities
Main entities:
•	User (common auth-level identity)
•	Parent
•	Student (includes blind students)
•	Teacher
•	Parent–Student Link
•	Teacher–Student Link
•	Assignments + Submissions
•	Chats (Parent ↔ Teacher per student)
•	Study Sessions + App Usage Events
•	App Block Policies
•	Notification Tokens
•	(Optional) LLM Classification Logs, Audit Logs
________________________________________
2. Authentication vs Firestore
Firebase Auth
Auth user has:
•	uid (primary key)
•	email
•	phoneNumber
•	password
•	displayName
We mirror some of this into Firestore users for app logic.
________________________________________
3. Core Collections Overview
Top-level collections:
/users
/parents
/students
/teachers
/parent_student_links
/teacher_student_links
/assignments
/assignment_submissions
/chat_threads
/study_sessions
/app_policies
/notifications
/llm_classifications (optional)
/audit_logs (optional)
________________________________________
4. users Collection
Path: /users/{userId} where {userId} = Firebase Auth uid.
Fields (example):
•	uid: string (same as doc ID)
•	role: string ("parent" | "student" | "teacher")
•	email: string
•	phone: string
•	displayName: string
•	createdAt: timestamp
•	updatedAt: timestamp
•	isActive: boolean (soft delete / block)
•	lastLoginAt: timestamp
•	fcmTokens: array<string> (for quick send; full details in devices collection)
Constraint:
•	Every authenticated user must have a corresponding /users/{uid}.
•	Enforced via Cloud Function on onCreate of Auth.
________________________________________
5. Role-Specific Collections
5.1 /parents
Path: /parents/{parentId} (parentId = uid)
Fields:
•	userId: string (ref → /users/{uid})
•	fullName: string
•	phone: string
•	email: string
•	address: string
•	childrenIds: array<string> (optional cache of student IDs)
•	createdAt: timestamp
•	updatedAt: timestamp
Relations:
•	userId ↔ /users/{uid} (role = "parent")
•	Children via /parent_student_links or childrenIds.
________________________________________
5.2 /students
Path: /students/{studentId} (you can use custom code like SCHL2025_0001 or random)
Fields:
•	studentId: string (same as doc ID)
•	userId: string | null
o	If students log in individually using Auth → store uid here.
•	fullName: string
•	grade: string (e.g., "8", "10")
•	section: string (e.g., "A")
•	schoolName: string
•	parentIds: array<string> (parent userIds)
•	teacherIds: array<string> (teacher userIds)
•	isBlind: boolean (if parent marks disability=blind)
•	disabilities: array<string> (e.g., ["blind"] for future extensibility)
•	voiceOnlyMode: boolean (for blind mode)
•	studyModeEnabled: boolean (last known status)
•	createdAt: timestamp
•	updatedAt: timestamp
Relations:
•	Linked to parents via /parent_student_links
•	Linked to teachers via /teacher_student_links
•	Used by assignments, study_sessions, chat_threads, etc.
________________________________________
5.3 /teachers
Path: /teachers/{teacherId} (teacherId = uid)
Fields:
•	userId: string (ref → /users/{uid})
•	fullName: string
•	email: string
•	phone: string
•	subjects: array<string> (e.g., ["Maths", "Physics"])
•	schoolName: string
•	assignedStudentIds: array<string> (cache list)
•	createdAt: timestamp
•	updatedAt: timestamp
Relations:
•	Students via /teacher_student_links
•	Chats via /chat_threads (teacherId included in participants)
________________________________________
6. Relationship Collections
6.1 /parent_student_links
Path: /parent_student_links/{linkId}
Fields:
•	parentId: string (ref → /parents/{parentId})
•	studentId: string (ref → /students/{studentId})
•	createdAt: timestamp
•	status: string ("active" | "pending" | "revoked")
•	createdBy: string ("system" | "parent" | "admin")
•	notes: string
Constraint:
•	Unique pair (parentId, studentId).
•	Enforce via composite index + Cloud Function (onCreate checks if existing).
________________________________________
6.2 /teacher_student_links
Path: /teacher_student_links/{linkId}
Fields:
•	teacherId: string (ref → /teachers/{teacherId})
•	studentId: string (ref → /students/{studentId})
•	createdAt: timestamp
•	status: string ("active" | "pending" | "revoked")
•	createdBy: string ("parent" | "admin" | "teacher" but you can restrict in rules)
Constraint:
•	Teacher cannot create new student docs. They can only link to existing studentId.
•	Implement in UI + Cloud Function.
________________________________________
7. App Block Policies
/app_policies
You want parent-specific blocking per student.
Path: /app_policies/{policyId}
You can choose policyId = "{studentId}_{parentId}" or auto-id with fields.
Fields:
•	studentId: string (ref → /students/{studentId})
•	parentId: string (ref → /parents/{parentId})
•	blockedApps: array<object> of:
o	packageName: string (e.g., "com.google.android.youtube")
o	appName: string (e.g., "YouTube")
o	blockedReason: string (optional)
•	whitelistedAppsDuringStudyMode: array<string> (package names)
•	blockAllExceptWhitelistedDuringStudy: boolean
•	enforceAtSystemLevel: boolean (if you plan root/MDM later)
•	updatedBy: string ("parentId")
•	updatedAt: timestamp
•	createdAt: timestamp
Usage:
•	When student enables Study Mode, Flutter fetches their policies.
•	Accessibility service checks running apps against blockedApps and handles blocking/alerts.
________________________________________
8. Study Mode & Monitoring
8.1 /study_sessions
Each time student starts study mode → new session.
Path: /study_sessions/{sessionId}
Fields:
•	sessionId: string (doc ID)
•	studentId: string
•	deviceId: string (device fingerprint / UUID)
•	startedAt: timestamp
•	endedAt: timestamp | null
•	isActive: boolean
•	totalDurationSec: number (optional; filled on end)
•	totalFocusDurationSec: number (optional; after analysis)
•	totalDistractionEvents: number (from events)
•	createdBy: string (studentId)
•	createdAt: timestamp
•	updatedAt: timestamp
Subcollection: /study_sessions/{sessionId}/events
Path: /study_sessions/{sessionId}/events/{eventId}
Each event = app usage snapshot.
Fields:
•	timestamp: timestamp
•	appPackage: string
•	appName: string
•	screenTitle: string | null (from accessibility text)
•	capturedText: string | null (e.g., video title, page title)
•	classification: string ("educational" | "non_educational" | "unknown")
•	classificationScore: number (0–1 from LLM)
•	triggeredBy: string ("accessibility_service" | "manual")
•	blocked: boolean
•	alertSentToParent: boolean
•	alertId: string | null (ref to /notifications/{id})
Real-time:
Parent dashboard listens to:
where("studentId", "==", someStudent).where("isActive", "==", true) on study_sessions,
and events subcollection with realtime snapshots.
________________________________________
9. LLM Classification Logs (Optional)
/llm_classifications
For debugging and future improvement.
Fields:
•	eventRef: document reference → /study_sessions/{sessionId}/events/{eventId}
•	studentId: string
•	inputText: string (truncated)
•	modelUsed: string (e.g., "gpt-4.1-mini")
•	classification: string
•	score: number
•	createdAt: timestamp
________________________________________
10. Assignments & Submissions
10.1 /assignments
Assignments can be created by parent or teacher, assigned to a student.
Path: /assignments/{assignmentId}
Fields:
•	assignmentId: string
•	createdByType: string ("parent" | "teacher")
•	createdById: string (parentId or teacherId)
•	studentId: string
•	title: string
•	description: string
•	attachments: array<object>:
o	fileUrl: string
o	fileType: string
•	dueDate: timestamp | null
•	status: string ("assigned" | "in_progress" | "completed" | "overdue")
•	createdAt: timestamp
•	updatedAt: timestamp
Student dashboard: filters where("studentId", "==", studentId).
________________________________________
10.2 /assignment_submissions
Separate collection for scale.
Path: /assignment_submissions/{submissionId}
Fields:
•	submissionId: string
•	assignmentId: string (ref → /assignments/{assignmentId})
•	studentId: string
•	submittedBy: string (student userId)
•	submittedAt: timestamp
•	content: string (text answer)
•	attachments: array<object> (similar)
•	status: string ("submitted" | "reviewed")
•	reviewedById: string | null (parent/teacher)
•	reviewNotes: string | null
•	grade: string | null
________________________________________
11. Chats (Parent ↔ Teacher per Student)
/chat_threads
Each thread = 1 parent + 1 teacher (and a specific student).
Path: /chat_threads/{threadId}
Fields:
•	threadId: string
•	studentId: string
•	parentId: string
•	teacherId: string
•	participants: array<string> (userIds)
•	lastMessageText: string
•	lastMessageAt: timestamp
•	lastMessageSenderId: string
•	createdAt: timestamp
•	updatedAt: timestamp
Constraint:
•	1 thread per (parentId, teacherId, studentId) combination.
•	Enforced via search + function before creating new.
Subcollection: /chat_threads/{threadId}/messages/{messageId}
Fields:
•	messageId: string
•	senderId: string
•	senderRole: string ("parent" | "teacher")
•	text: string
•	attachments: array<object>
•	createdAt: timestamp
•	seenBy: array<string> (userIds)
•	deletedFor: array<string> (userIds who soft-deleted)
________________________________________
12. Notifications
/notifications
System log of notifications sent (optional but useful).
Path: /notifications/{notificationId}
Fields:
•	notificationId: string
•	userId: string (who receives it – parent usually)
•	title: string
•	body: string
•	type: string ("app_block_alert" | "assignment_due" | "general")
•	data: map (extra info: studentId, sessionId, eventId)
•	sentAt: timestamp
•	delivered: boolean
•	readAt: timestamp | null
________________________________________
/users/{userId}/devices/{deviceId}
For detailed FCM token info.
Fields:
•	deviceId: string
•	fcmToken: string
•	platform: string ("android" | "ios" | "web")
•	lastActiveAt: timestamp
•	createdAt: timestamp
________________________________________
13. Blind Mode / Voice-Only Logic
Blind students use the same students + study_sessions + assignments etc.
Key flags:
•	In /students/{studentId}:
o	isBlind: boolean
o	voiceOnlyMode: boolean
•	In app logic:
o	When app opens, ask via voice: “Are you blind?”
o	If yes, enforce:
	All navigation via voice commands (client-side behavior)
	No extra DB needed except maybe logs.
Optional: store voice preference.
/students/{studentId}/accessibility_profile
Fields (optional):
•	isBlind: boolean
•	preferredLanguage: string (e.g., "en-IN")
•	speechRate: number
•	pitch: number
•	lastUpdatedAt: timestamp
________________________________________
14. AI Chatbot (Doubt Solver)
You might want logs per student for analytics.
/ai_sessions
Path: /ai_sessions/{sessionId}
Fields:
•	sessionId: string
•	studentId: string
•	startedAt: timestamp
•	endedAt: timestamp | null
Subcollection: /ai_sessions/{sessionId}/messages/{messageId}
Fields:
•	messageId: string
•	senderType: string ("student" | "ai")
•	text: string
•	createdAt: timestamp
•	topic: string | null (e.g., "Maths/Algebra")
•	modelUsed: string (for AI responses)
(This is optional – you can skip logging if cost/space is a concern.)
________________________________________
15. Security & Constraints (Conceptual)
You’ll enforce constraints mostly via Security Rules + Cloud Functions + Client Logic, not DB itself.
Examples:
•	Parents can:
o	Read their own /parents/{parentId}
o	Read/write /parent_student_links where parentId == request.auth.uid
o	Read/write /app_policies where parentId == request.auth.uid
o	Read /students/{studentId} only if linked via parent_student_links
•	Students can:
o	Read/update only their own /students/{studentId} (by userId)
o	Read their own assignments (studentId == currentStudentId)
o	Create study_sessions and events only for themselves.
•	Teachers can:
o	Read students only when linked via /teacher_student_links
o	Create assignments for linked students
o	Chat only in chat_threads where they’re a participant.
•	Blind logic is client-side; DB only stores isBlind.

