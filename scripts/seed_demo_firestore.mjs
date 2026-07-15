/**
 * One-shot Firestore demo seed for a single TaskFlow account.
 *
 * Target: dohoangduong2708@gmail.com
 * UID:    OHZF9pDh8vY3uoyPIHseaz3ZKh72
 *
 * Deletes existing subcollections under that user (keeps profile fields),
 * then writes a full demo: projects, tasks, focusSessions, notifications, settings.
 *
 * Usage (from repo root, Firebase CLI must already be logged in):
 *   node scripts/seed_demo_firestore.mjs
 */

import { readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const PROJECT_ID = 'taskflow-4fd64';
const UID = 'OHZF9pDh8vY3uoyPIHseaz3ZKh72';
const EXPECTED_EMAIL = 'dohoangduong2708@gmail.com';

// Public Firebase CLI OAuth client (used by firebase-tools).
const CLI_CLIENT_ID =
  '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com';
const CLI_CLIENT_SECRET = 'jEQV8uHoLvuTr7a_RS_sNkjc';

const FIRESTORE_BASE = `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}/databases/(default)/documents`;
const USER_PATH = `users/${UID}`;

function dayAt(offsetDays, hour = 12, minute = 0) {
  const d = new Date();
  d.setHours(hour, minute, 0, 0);
  d.setDate(d.getDate() + offsetDays);
  return d;
}

function iso(date) {
  return date.toISOString();
}

function str(v) {
  return { stringValue: String(v) };
}

function int(v) {
  return { integerValue: String(Math.trunc(v)) };
}

function bool(v) {
  return { booleanValue: Boolean(v) };
}

function ts(date) {
  return { timestampValue: iso(date instanceof Date ? date : new Date(date)) };
}

function arr(values) {
  return { arrayValue: { values } };
}

function map(fields) {
  return { mapValue: { fields } };
}

function omitNull(fields) {
  const out = {};
  for (const [k, v] of Object.entries(fields)) {
    if (v != null) out[k] = v;
  }
  return out;
}

function loadFirebaseTokens() {
  const path = join(homedir(), '.config', 'configstore', 'firebase-tools.json');
  const raw = JSON.parse(readFileSync(path, 'utf8'));
  if (!raw.tokens?.refresh_token) {
    throw new Error('No Firebase CLI refresh_token. Run: firebase login');
  }
  return raw.tokens;
}

async function getAccessToken(tokens) {
  if (tokens.access_token && tokens.expires_at && tokens.expires_at > Date.now() + 60_000) {
    return tokens.access_token;
  }

  const body = new URLSearchParams({
    grant_type: 'refresh_token',
    refresh_token: tokens.refresh_token,
    client_id: CLI_CLIENT_ID,
    client_secret: CLI_CLIENT_SECRET,
  });
  const res = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  if (!res.ok) {
    throw new Error(
      `Token refresh failed: ${res.status} ${await res.text()}\n` +
        'Re-login with: firebase login --reauth',
    );
  }
  const json = await res.json();
  return json.access_token;
}

async function firestore(accessToken, method, path, body) {
  const url = path.startsWith('http')
    ? path
    : `${FIRESTORE_BASE}/${path.replace(/^\//, '')}`;
  const res = await fetch(url, {
    method,
    headers: {
      Authorization: `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (res.status === 404) return null;
  if (!res.ok) {
    throw new Error(`${method} ${url} -> ${res.status}: ${await res.text()}`);
  }
  if (res.status === 204) return null;
  return res.json();
}

async function listCollection(accessToken, collectionPath) {
  const docs = [];
  let pageToken;
  do {
    const qs = new URLSearchParams({ pageSize: '300' });
    if (pageToken) qs.set('pageToken', pageToken);
    const data = await firestore(
      accessToken,
      'GET',
      `${collectionPath}?${qs}`,
    );
    if (!data) break;
    docs.push(...(data.documents ?? []));
    pageToken = data.nextPageToken;
  } while (pageToken);
  return docs;
}

async function deleteDoc(accessToken, docName) {
  // docName is full resource name: projects/.../documents/users/...
  const suffix = docName.split('/documents/')[1];
  await firestore(accessToken, 'DELETE', suffix);
}

async function clearCollection(accessToken, collectionPath) {
  const docs = await listCollection(accessToken, collectionPath);
  for (const doc of docs) {
    await deleteDoc(accessToken, doc.name);
  }
  console.log(`  cleared ${collectionPath} (${docs.length} docs)`);
}

async function setDoc(accessToken, docPath, fields) {
  const mask = Object.keys(fields)
    .map((k) => `updateMask.fieldPaths=${encodeURIComponent(k)}`)
    .join('&');
  await firestore(accessToken, 'PATCH', `${docPath}?${mask}`, { fields });
}

function buildSeedData() {
  const now = new Date();

  const projects = [
    {
      id: 'seed_proj_taskflow',
      name: 'TaskFlow App',
      description: 'PRM392 Flutter productivity app — screens, Firebase sync, polish.',
      colorValue: 0xff2e7d32,
      iconName: 'code',
      status: 'In Progress',
    },
    {
      id: 'seed_proj_study',
      name: 'Study Sprint',
      description: 'Exam prep and weekly reading goals.',
      colorValue: 0xff0277bd,
      iconName: 'school_outlined',
      status: 'In Progress',
    },
    {
      id: 'seed_proj_personal',
      name: 'Personal',
      description: 'Errands, health, and life admin.',
      colorValue: 0xffc2185b,
      iconName: 'home_outlined',
      status: 'In Progress',
    },
    {
      id: 'seed_proj_design',
      name: 'UI Polish',
      description: 'Design system tweaks and visual consistency.',
      colorValue: 0xff7b1fa2,
      iconName: 'brush_outlined',
      status: 'In Progress',
    },
    {
      id: 'seed_proj_archive',
      name: 'Onboarding Done',
      description: 'Completed setup tasks for the demo account.',
      colorValue: 0xff455a64,
      iconName: 'rocket_launch_outlined',
      status: 'Completed',
    },
  ];

  /** @type {Array<Record<string, any>>} */
  const tasks = [
    // —— Today (all due-today tasks completed → streak day) ——
    {
      id: 'seed_task_done_today_a',
      title: 'Morning review: Firebase seed & Home',
      projectId: 'seed_proj_taskflow',
      priority: 'High',
      dueDate: dayAt(0, 9, 0),
      createdAt: dayAt(-2, 10, 0),
      completedAt: dayAt(0, 8, 40),
      isCompleted: true,
      isImportant: true,
      isAllDay: false,
      notes: 'Completed today for 5-day streak.',
      reminder: 'None',
      subTasks: [
        { id: 'st1', title: 'Open Projects list', isCompleted: true },
        { id: 'st2', title: 'Check Statistics charts', isCompleted: true },
      ],
    },
    {
      id: 'seed_task_done_today_b',
      title: 'Push card-appearance defaults',
      projectId: 'seed_proj_taskflow',
      priority: 'Medium',
      dueDate: dayAt(0, 11, 0),
      createdAt: dayAt(-2, 10, 0),
      completedAt: dayAt(0, 10, 20),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_done_today_c',
      title: 'Evening walk 30 mins',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(0, 18, 0),
      createdAt: dayAt(-3, 7, 0),
      completedAt: dayAt(0, 18, 15),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },

    // —— Active demos moved off today (keep list busy without breaking streak) ——
    {
      id: 'seed_task_today_meeting',
      title: 'Stand-up: TaskFlow progress',
      projectId: 'seed_proj_taskflow',
      priority: 'Medium',
      dueDate: dayAt(1, 14, 30),
      createdAt: dayAt(-1, 8, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: '15 mins before',
      subTasks: [],
    },
    {
      id: 'seed_task_today_allday',
      title: 'Weekly planning (all day)',
      projectId: 'seed_proj_personal',
      priority: 'Medium',
      dueDate: dayAt(1, 12, 0),
      createdAt: dayAt(-2, 18, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: true,
      notes: 'Block focus time and rest day.',
      reminder: '1 day before',
      subTasks: [],
    },
    {
      id: 'seed_task_focus_target',
      title: 'Deep work: statistics screen polish',
      projectId: 'seed_proj_design',
      priority: 'High',
      dueDate: dayAt(1, 16, 0),
      createdAt: dayAt(-2, 15, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'Pair with a pomodoro session.',
      reminder: '15 mins before',
      subTasks: [],
    },
    {
      id: 'seed_task_today_inbox_call',
      title: 'Call clinic for appointment',
      projectId: null,
      priority: 'Medium',
      dueDate: dayAt(2, 11, 15),
      createdAt: dayAt(-1, 19, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: 'No project — inbox style card.',
      reminder: '10 mins before',
      subTasks: [],
    },

    // —— Streak days d-1 … d-4 (task due+done same day + focus ≥60m) ——
    {
      id: 'seed_streak_d1_a',
      title: 'Finish auth sign-out theme reset',
      projectId: 'seed_proj_taskflow',
      priority: 'High',
      dueDate: dayAt(-1, 17, 0),
      createdAt: dayAt(-6, 12, 0),
      completedAt: dayAt(-1, 17, 20),
      isCompleted: true,
      isImportant: true,
      isAllDay: false,
      notes: 'Streak day -1',
      reminder: 'None',
      subTasks: [
        { id: 'st1', title: 'Keep brightness', isCompleted: true },
        { id: 'st2', title: 'Reset activity mode', isCompleted: true },
      ],
    },
    {
      id: 'seed_streak_d1_b',
      title: 'Inbox triage before bed',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(-1, 21, 0),
      createdAt: dayAt(-2, 9, 0),
      completedAt: dayAt(-1, 21, 10),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_streak_d2_a',
      title: 'Tweak drawer swipe on Projects',
      projectId: 'seed_proj_taskflow',
      priority: 'Medium',
      dueDate: dayAt(-2, 13, 0),
      createdAt: dayAt(-5, 10, 0),
      completedAt: dayAt(-2, 14, 10),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: 'Streak day -2',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_streak_d2_b',
      title: 'Design: statistics card spacing',
      projectId: 'seed_proj_design',
      priority: 'Medium',
      dueDate: dayAt(-2, 16, 0),
      createdAt: dayAt(-4, 11, 0),
      completedAt: dayAt(-2, 16, 40),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_streak_d3_a',
      title: 'Study notes: Firestore queries',
      projectId: 'seed_proj_study',
      priority: 'High',
      dueDate: dayAt(-3, 19, 0),
      createdAt: dayAt(-7, 10, 0),
      completedAt: dayAt(-3, 19, 30),
      isCompleted: true,
      isImportant: true,
      isAllDay: false,
      notes: 'Streak day -3',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_streak_d4_a',
      title: 'Finish chapter: Async programming',
      projectId: 'seed_proj_study',
      priority: 'Medium',
      dueDate: dayAt(-4, 20, 0),
      createdAt: dayAt(-10, 9, 0),
      completedAt: dayAt(-4, 21, 5),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: 'Streak day -4 (start of 5-day streak)',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_streak_d4_b',
      title: 'Ship small UI fix: empty projects state',
      projectId: 'seed_proj_taskflow',
      priority: 'Low',
      dueDate: dayAt(-4, 11, 0),
      createdAt: dayAt(-8, 9, 0),
      completedAt: dayAt(-4, 11, 45),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },

    // —— Day -5: break streak (tasks done but focus short) ——
    {
      id: 'seed_break_d5',
      title: 'Quick tidy: folder icons review',
      projectId: 'seed_proj_design',
      priority: 'Low',
      dueDate: dayAt(-5, 12, 0),
      createdAt: dayAt(-8, 10, 0),
      completedAt: dayAt(-5, 12, 30),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: 'Break day — focus under 60m so streak caps at 5.',
      reminder: 'None',
      subTasks: [],
    },

    // —— Overdue (spread) ——
    {
      id: 'seed_task_overdue_bug',
      title: 'Fix project list delete animation jerk',
      projectId: 'seed_proj_taskflow',
      priority: 'High',
      dueDate: dayAt(-8, 9, 30),
      createdAt: dayAt(-12, 10, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'ListView + SizeTransition — avoid layout jump.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_overdue_week',
      title: 'Write unit notes for Firebase Auth',
      projectId: 'seed_proj_study',
      priority: 'Medium',
      dueDate: dayAt(-6, 18, 0),
      createdAt: dayAt(-12, 11, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'Overdue ~1 week.',
      reminder: 'None',
      subTasks: [
        { id: 'st1', title: 'Email/password flow', isCompleted: true },
        { id: 'st2', title: 'Google Sign-In notes', isCompleted: false },
      ],
    },
    {
      id: 'seed_task_overdue_2w',
      title: 'Order new keyboard switches',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(-14, 12, 0),
      createdAt: dayAt(-20, 16, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: true,
      notes: 'Soft overdue life admin.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_overdue_month',
      title: 'Backup Figma export of old screens',
      projectId: 'seed_proj_design',
      priority: 'Low',
      dueDate: dayAt(-28, 12, 0),
      createdAt: dayAt(-40, 10, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: true,
      notes: 'Month-old overdue for calendar depth.',
      reminder: 'None',
      subTasks: [],
    },

    // —— Tomorrow / this week ——
    {
      id: 'seed_task_tomorrow_study',
      title: 'Revise Flutter Provider patterns',
      projectId: 'seed_proj_study',
      priority: 'High',
      dueDate: dayAt(1, 19, 0),
      createdAt: dayAt(-4, 11, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'ChangeNotifier + ProxyProvider refresh.',
      reminder: '1 hour before',
      subTasks: [
        { id: 'st1', title: 'Read docs notes', isCompleted: false },
        { id: 'st2', title: 'Rewrite one provider cleanly', isCompleted: false },
      ],
    },
    {
      id: 'seed_task_no_project',
      title: 'Buy groceries for the week',
      projectId: null,
      priority: 'Low',
      dueDate: dayAt(1, 12, 0),
      createdAt: dayAt(-1, 20, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: true,
      notes: 'Milk, eggs, veggies.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_design',
      title: 'Align edit-project cards with task details tint',
      projectId: 'seed_proj_design',
      priority: 'Medium',
      dueDate: dayAt(2, 15, 0),
      createdAt: dayAt(-2, 13, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: '10 mins before',
      subTasks: [],
    },
    {
      id: 'seed_task_later_week',
      title: 'Write demo script for presentation',
      projectId: 'seed_proj_study',
      priority: 'Medium',
      dueDate: dayAt(3, 10, 0),
      createdAt: dayAt(-1, 9, 30),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: 'Cover Home → Projects → Tasks → Focus → Goals.',
      reminder: '1 day before',
      subTasks: [],
    },
    {
      id: 'seed_task_d5_focus_qa',
      title: 'QA Focus timer + fullscreen resume',
      projectId: 'seed_proj_taskflow',
      priority: 'High',
      dueDate: dayAt(5, 11, 0),
      createdAt: dayAt(-1, 12, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: '',
      reminder: '30 mins before',
      subTasks: [],
    },
    {
      id: 'seed_task_d6_laundry',
      title: 'Do laundry & tidy desk',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(6, 12, 0),
      createdAt: dayAt(0, 8, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: true,
      notes: '',
      reminder: '1 day before',
      subTasks: [],
    },

    // —— Next 2–4 weeks ——
    {
      id: 'seed_task_w2_release',
      title: 'Prepare APK release checklist',
      projectId: 'seed_proj_taskflow',
      priority: 'High',
      dueDate: dayAt(10, 16, 0),
      createdAt: dayAt(-3, 14, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'Signing, version, smoke test matrix.',
      reminder: '1 day before',
      subTasks: [
        { id: 'st1', title: 'Bump versionCode', isCompleted: false },
        { id: 'st2', title: 'Test Google Sign-In release SHA', isCompleted: false },
        { id: 'st3', title: 'Record demo clip', isCompleted: false },
      ],
    },
    {
      id: 'seed_task_w2_design_pass',
      title: 'Second visual pass: Statistics dark mode',
      projectId: 'seed_proj_design',
      priority: 'Medium',
      dueDate: dayAt(12, 14, 0),
      createdAt: dayAt(-2, 9, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: '1 hour before',
      subTasks: [],
    },
    {
      id: 'seed_task_w3_midterm',
      title: 'Practice midterm mock quiz',
      projectId: 'seed_proj_study',
      priority: 'High',
      dueDate: dayAt(18, 9, 0),
      createdAt: dayAt(-7, 10, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: true,
      notes: 'All-day exam prep block.',
      reminder: '1 week before',
      subTasks: [],
    },
    {
      id: 'seed_task_w3_haircut',
      title: 'Haircut appointment',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(20, 15, 30),
      createdAt: dayAt(-1, 11, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: '1 day before',
      subTasks: [],
    },
    {
      id: 'seed_task_w4_retro',
      title: 'Sprint retro notes for TaskFlow',
      projectId: 'seed_proj_taskflow',
      priority: 'Medium',
      dueDate: dayAt(25, 17, 0),
      createdAt: dayAt(0, 9, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: 'What went well / next improvements.',
      reminder: '30 mins before',
      subTasks: [],
    },

    // —— Next month+ ——
    {
      id: 'seed_task_m1_portfolio',
      title: 'Update portfolio with TaskFlow screenshots',
      projectId: 'seed_proj_design',
      priority: 'Medium',
      dueDate: dayAt(35, 12, 0),
      createdAt: dayAt(-5, 15, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: true,
      notes: 'Capture Home, Goals, Calendar.',
      reminder: '1 week before',
      subTasks: [],
    },
    {
      id: 'seed_task_m1_exam',
      title: 'Final PRM392 presentation day',
      projectId: 'seed_proj_study',
      priority: 'High',
      dueDate: dayAt(42, 8, 30),
      createdAt: dayAt(-10, 8, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'Bring laptop + APK + slide deck.',
      reminder: '1 day before',
      subTasks: [
        { id: 'st1', title: 'Export slides PDF', isCompleted: false },
        { id: 'st2', title: 'Rehearse 5-min pitch', isCompleted: false },
      ],
    },
    {
      id: 'seed_task_m2_travel',
      title: 'Plan weekend day trip',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(50, 12, 0),
      createdAt: dayAt(-2, 20, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: true,
      notes: 'Far-future calendar filler.',
      reminder: '1 week before',
      subTasks: [],
    },

    // —— Far past completed (history / stats) ——
    {
      id: 'seed_task_done_archive',
      title: 'Create Firebase project & enable Auth',
      projectId: 'seed_proj_archive',
      priority: 'High',
      dueDate: dayAt(-7, 14, 0),
      createdAt: dayAt(-14, 9, 0),
      completedAt: dayAt(-7, 15, 0),
      isCompleted: true,
      isImportant: false,
      isAllDay: true,
      notes: 'Demo archive project should show Completed.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_done_w2',
      title: 'Wire notification bell across screens',
      projectId: 'seed_proj_taskflow',
      priority: 'Medium',
      dueDate: dayAt(-10, 16, 0),
      createdAt: dayAt(-16, 9, 0),
      completedAt: dayAt(-10, 17, 30),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_done_w3',
      title: 'Sketch Goals streak hero variants',
      projectId: 'seed_proj_design',
      priority: 'Medium',
      dueDate: dayAt(-16, 12, 0),
      createdAt: dayAt(-22, 10, 0),
      completedAt: dayAt(-16, 18, 0),
      isCompleted: true,
      isImportant: true,
      isAllDay: true,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_done_w4',
      title: 'Read Cloud Firestore data model docs',
      projectId: 'seed_proj_study',
      priority: 'Low',
      dueDate: dayAt(-21, 19, 0),
      createdAt: dayAt(-28, 14, 0),
      completedAt: dayAt(-21, 20, 10),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_done_month',
      title: 'Register Android app package + SHA-1',
      projectId: 'seed_proj_archive',
      priority: 'High',
      dueDate: dayAt(-32, 12, 0),
      createdAt: dayAt(-40, 9, 0),
      completedAt: dayAt(-32, 13, 0),
      isCompleted: true,
      isImportant: false,
      isAllDay: true,
      notes: 'Early onboarding history.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_done_6w',
      title: 'Project kickoff: feature list backlog',
      projectId: 'seed_proj_archive',
      priority: 'Medium',
      dueDate: dayAt(-40, 10, 0),
      createdAt: dayAt(-45, 9, 0),
      completedAt: dayAt(-40, 11, 30),
      isCompleted: true,
      isImportant: true,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },

    // —— Extra completions for Statistics charts (spread hours / weeks) ——
    {
      id: 'seed_stats_d9',
      title: 'Fix typo on login branding',
      projectId: 'seed_proj_taskflow',
      priority: 'Low',
      dueDate: dayAt(-9, 9, 0),
      createdAt: dayAt(-11, 8, 0),
      completedAt: dayAt(-9, 9, 40),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d11',
      title: 'Document Firestore paths helper',
      projectId: 'seed_proj_study',
      priority: 'Medium',
      dueDate: dayAt(-11, 14, 0),
      createdAt: dayAt(-13, 10, 0),
      completedAt: dayAt(-11, 14, 20),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d15',
      title: 'Tone down dark-mode borders',
      projectId: 'seed_proj_design',
      priority: 'Medium',
      dueDate: dayAt(-15, 17, 0),
      createdAt: dayAt(-17, 11, 0),
      completedAt: dayAt(-15, 17, 45),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d19',
      title: 'Grocery run after class',
      projectId: 'seed_proj_personal',
      priority: 'Low',
      dueDate: dayAt(-19, 18, 30),
      createdAt: dayAt(-20, 9, 0),
      completedAt: dayAt(-19, 19, 0),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d22',
      title: 'Review PR checklist for screens',
      projectId: 'seed_proj_taskflow',
      priority: 'High',
      dueDate: dayAt(-22, 11, 0),
      createdAt: dayAt(-24, 10, 0),
      completedAt: dayAt(-22, 11, 50),
      isCompleted: true,
      isImportant: true,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d25',
      title: 'Read Provider docs chapter 3',
      projectId: 'seed_proj_study',
      priority: 'Medium',
      dueDate: dayAt(-25, 20, 0),
      createdAt: dayAt(-27, 15, 0),
      completedAt: dayAt(-25, 21, 10),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d30',
      title: 'Update app icon drafts',
      projectId: 'seed_proj_design',
      priority: 'Low',
      dueDate: dayAt(-30, 15, 0),
      createdAt: dayAt(-33, 12, 0),
      completedAt: dayAt(-30, 15, 35),
      isCompleted: true,
      isImportant: false,
      isAllDay: false,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_stats_d35',
      title: 'Pay phone bill',
      projectId: 'seed_proj_personal',
      priority: 'Medium',
      dueDate: dayAt(-35, 12, 0),
      createdAt: dayAt(-36, 8, 0),
      completedAt: dayAt(-35, 12, 15),
      isCompleted: true,
      isImportant: false,
      isAllDay: true,
      notes: '',
      reminder: 'None',
      subTasks: [],
    },

    // —— Unscheduled inbox ——
    {
      id: 'seed_task_inbox',
      title: 'Reply to mentor email',
      projectId: null,
      priority: 'Medium',
      dueDate: null,
      createdAt: dayAt(-5, 16, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: 'Unscheduled inbox item.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_inbox_idea',
      title: 'Idea: swipe-to-snooze on task cards',
      projectId: null,
      priority: 'Low',
      dueDate: null,
      createdAt: dayAt(-12, 21, 0),
      isCompleted: false,
      isImportant: true,
      isAllDay: false,
      notes: 'Parked idea — no due date.',
      reminder: 'None',
      subTasks: [],
    },
    {
      id: 'seed_task_inbox_lib',
      title: 'Explore flutter_slidable edge cases',
      projectId: 'seed_proj_taskflow',
      priority: 'Low',
      dueDate: null,
      createdAt: dayAt(-8, 15, 0),
      isCompleted: false,
      isImportant: false,
      isAllDay: false,
      notes: 'Research backlog, unscheduled.',
      reminder: 'None',
      subTasks: [],
    },
  ];

  const focusSessions = [
    // Today — ≥60m (streak)
    {
      id: 'seed_focus_d0_a',
      title: 'Morning review: Firebase seed & Home',
      taskId: 'seed_task_done_today_a',
      time: dayAt(0, 8, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d0_b',
      title: 'Push card-appearance defaults',
      taskId: 'seed_task_done_today_b',
      time: dayAt(0, 10, 0),
      durationMinutes: 25,
    },
    // d-1 — ≥60m
    {
      id: 'seed_focus_d1_a',
      title: 'Finish auth sign-out theme reset',
      taskId: 'seed_streak_d1_a',
      time: dayAt(-1, 15, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d1_b',
      title: 'Inbox triage before bed',
      taskId: 'seed_streak_d1_b',
      time: dayAt(-1, 20, 0),
      durationMinutes: 25,
    },
    // d-2 — ≥60m
    {
      id: 'seed_focus_d2_a',
      title: 'Tweak drawer swipe on Projects',
      taskId: 'seed_streak_d2_a',
      time: dayAt(-2, 13, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d2_b',
      title: 'Design: statistics card spacing',
      taskId: 'seed_streak_d2_b',
      time: dayAt(-2, 16, 0),
      durationMinutes: 50,
    },
    // d-3 — ≥60m
    {
      id: 'seed_focus_d3_a',
      title: 'Study notes: Firestore queries',
      taskId: 'seed_streak_d3_a',
      time: dayAt(-3, 18, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d3_b',
      title: 'Free focus block',
      taskId: null,
      time: dayAt(-3, 10, 0),
      durationMinutes: 25,
    },
    // d-4 — ≥60m (streak start)
    {
      id: 'seed_focus_d4_a',
      title: 'Finish chapter: Async programming',
      taskId: 'seed_streak_d4_a',
      time: dayAt(-4, 19, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d4_b',
      title: 'Ship small UI fix: empty projects state',
      taskId: 'seed_streak_d4_b',
      time: dayAt(-4, 11, 0),
      durationMinutes: 25,
    },
    // d-5 — only 25m (break streak)
    {
      id: 'seed_focus_d5_short',
      title: 'Quick tidy: folder icons review',
      taskId: 'seed_break_d5',
      time: dayAt(-5, 11, 0),
      durationMinutes: 25,
    },
    // Broader history for Statistics (scattered complete + incomplete weeks)
    {
      id: 'seed_focus_d7',
      title: 'Create Firebase project & enable Auth',
      taskId: 'seed_task_done_archive',
      time: dayAt(-7, 14, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d7b',
      title: 'Free focus block',
      taskId: null,
      time: dayAt(-7, 9, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d10',
      title: 'Wire notification bell across screens',
      taskId: 'seed_task_done_w2',
      time: dayAt(-10, 15, 0),
      durationMinutes: 75,
    },
    {
      id: 'seed_focus_d12',
      title: 'Afternoon deep work',
      taskId: null,
      time: dayAt(-12, 14, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d15',
      title: 'Tone down dark-mode borders',
      taskId: 'seed_stats_d15',
      time: dayAt(-15, 16, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d15b',
      title: 'Free focus block',
      taskId: null,
      time: dayAt(-15, 20, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d14',
      title: 'Sketch Goals streak hero variants',
      taskId: 'seed_task_done_w3',
      time: dayAt(-16, 10, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d16',
      title: 'Sketch Goals streak hero variants',
      taskId: 'seed_task_done_w3',
      time: dayAt(-16, 16, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d18',
      title: 'Study sprint block',
      taskId: null,
      time: dayAt(-18, 20, 0),
      durationMinutes: 45,
    },
    {
      id: 'seed_focus_d21',
      title: 'Read Cloud Firestore data model docs',
      taskId: 'seed_task_done_w4',
      time: dayAt(-21, 19, 30),
      durationMinutes: 70,
    },
    {
      id: 'seed_focus_d22',
      title: 'Review PR checklist for screens',
      taskId: 'seed_stats_d22',
      time: dayAt(-22, 10, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d22b',
      title: 'Review PR checklist for screens',
      taskId: 'seed_stats_d22',
      time: dayAt(-22, 15, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d24',
      title: 'Short evening session',
      taskId: null,
      time: dayAt(-24, 21, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d25',
      title: 'Read Provider docs chapter 3',
      taskId: 'seed_stats_d25',
      time: dayAt(-25, 19, 0),
      durationMinutes: 75,
    },
    {
      id: 'seed_focus_d28',
      title: 'Design polish block',
      taskId: null,
      time: dayAt(-28, 11, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d28b',
      title: 'Design polish block',
      taskId: null,
      time: dayAt(-28, 15, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d30',
      title: 'Update app icon drafts',
      taskId: 'seed_stats_d30',
      time: dayAt(-30, 14, 0),
      durationMinutes: 60,
    },
    {
      id: 'seed_focus_d32',
      title: 'Register Android app package + SHA-1',
      taskId: 'seed_task_done_month',
      time: dayAt(-32, 10, 0),
      durationMinutes: 60,
    },
    {
      id: 'seed_focus_d35',
      title: 'Pay phone bill',
      taskId: 'seed_stats_d35',
      time: dayAt(-35, 11, 0),
      durationMinutes: 25,
    },
    {
      id: 'seed_focus_d36',
      title: 'Mid-month catch-up',
      taskId: null,
      time: dayAt(-36, 13, 0),
      durationMinutes: 50,
    },
    {
      id: 'seed_focus_d40',
      title: 'Project kickoff: feature list backlog',
      taskId: 'seed_task_done_6w',
      time: dayAt(-40, 10, 30),
      durationMinutes: 90,
    },
  ];

  const notifications = [
    {
      id: 'seed_notif_reminder',
      category: 'taskReminder',
      title: 'Streak day secured',
      body: 'You completed today\'s task + focus goals. 5-day streak!',
      timestamp: dayAt(0, 10, 30),
      isRead: false,
      taskId: 'seed_task_done_today_a',
    },
    {
      id: 'seed_notif_due',
      category: 'taskDue',
      title: 'Overdue: Fix project list delete animation',
      body: 'This task was due over a week ago.',
      timestamp: dayAt(-1, 9, 0),
      isRead: false,
      taskId: 'seed_task_overdue_bug',
    },
    {
      id: 'seed_notif_due_old',
      category: 'taskDue',
      title: 'Still overdue: Firebase Auth notes',
      body: 'Due almost a week ago — catch up when you can.',
      timestamp: dayAt(-5, 18, 0),
      isRead: false,
      taskId: 'seed_task_overdue_week',
    },
    {
      id: 'seed_notif_focus',
      category: 'focus',
      title: 'Focus session logged',
      body: '75 minutes logged today toward your focus goal.',
      timestamp: dayAt(0, 10, 30),
      isRead: true,
      taskId: 'seed_task_done_today_b',
    },
    {
      id: 'seed_notif_goals',
      category: 'goals',
      title: 'Streak secured',
      body: 'Task + focus goals met yesterday. Keep it going!',
      timestamp: dayAt(-1, 21, 0),
      isRead: true,
      taskId: null,
    },
    {
      id: 'seed_notif_achievement',
      category: 'achievement',
      title: 'Achievement unlocked',
      body: 'Completed 10+ tasks — First Milestone.',
      timestamp: dayAt(-2, 18, 0),
      isRead: false,
      taskId: null,
    },
    {
      id: 'seed_notif_stats',
      category: 'statistics',
      title: 'Weekly summary ready',
      body: 'Check your productivity trends for this week.',
      timestamp: dayAt(-3, 8, 0),
      isRead: true,
      taskId: null,
    },
    {
      id: 'seed_notif_exam',
      category: 'taskReminder',
      title: 'Coming up: Final presentation',
      body: 'Scheduled in about 6 weeks — start slides early.',
      timestamp: dayAt(-1, 8, 0),
      isRead: true,
      taskId: 'seed_task_m1_exam',
    },
  ];

  const settings = {
    notificationsEnabled: true,
    taskRemindersEnabled: true,
    goalsInsightsEnabled: true,
    achievementsEnabled: true,
    quietHoursEnabled: true,
    quietHoursStart: '22:00',
    quietHoursEnd: '07:00',
    defaultTimedReminder: '30 mins before',
    defaultAllDayReminder: '1 day before',
    activitySchedules: {
      work: { enabled: true, start: '09:00', end: '17:00' },
      study: { enabled: true, start: '17:30', end: '21:00' },
      chill: { enabled: false, start: '21:00', end: '23:00' },
      sleep: { enabled: true, start: '23:00', end: '07:00' },
    },
  };

  return {
    now,
    projects,
    tasks,
    focusSessions,
    notifications,
    settings,
  };
}

function projectFields(p) {
  return {
    name: str(p.name),
    description: str(p.description),
    colorValue: int(p.colorValue),
    iconName: str(p.iconName),
    status: str(p.status),
  };
}

function taskFields(t) {
  return omitNull({
    title: str(t.title),
    projectId: t.projectId ? str(t.projectId) : null,
    priority: str(t.priority),
    dueDate: t.dueDate ? ts(t.dueDate) : null,
    createdAt: ts(t.createdAt),
    completedAt: t.completedAt ? ts(t.completedAt) : null,
    isCompleted: bool(t.isCompleted),
    isImportant: bool(t.isImportant),
    isAllDay: bool(t.isAllDay),
    notes: str(t.notes ?? ''),
    reminder: str(t.reminder ?? 'None'),
    subTasks: arr(
      (t.subTasks ?? []).map((st) =>
        map({
          id: str(st.id),
          title: str(st.title),
          isCompleted: bool(st.isCompleted),
        }),
      ),
    ),
  });
}

function focusFields(f) {
  return omitNull({
    title: str(f.title),
    taskId: f.taskId ? str(f.taskId) : null,
    time: ts(f.time),
    durationMinutes: int(f.durationMinutes),
  });
}

function notificationFields(n) {
  return omitNull({
    category: str(n.category),
    title: str(n.title),
    body: str(n.body),
    timestamp: ts(n.timestamp),
    isRead: bool(n.isRead),
    taskId: n.taskId ? str(n.taskId) : null,
  });
}

function settingsFields(s) {
  return {
    notificationsEnabled: bool(s.notificationsEnabled),
    taskRemindersEnabled: bool(s.taskRemindersEnabled),
    goalsInsightsEnabled: bool(s.goalsInsightsEnabled),
    achievementsEnabled: bool(s.achievementsEnabled),
    quietHoursEnabled: bool(s.quietHoursEnabled),
    quietHoursStart: str(s.quietHoursStart),
    quietHoursEnd: str(s.quietHoursEnd),
    defaultTimedReminder: str(s.defaultTimedReminder),
    defaultAllDayReminder: str(s.defaultAllDayReminder),
    activitySchedules: map(
      Object.fromEntries(
        Object.entries(s.activitySchedules).map(([key, value]) => [
          key,
          map({
            enabled: bool(value.enabled),
            start: str(value.start),
            end: str(value.end),
          }),
        ]),
      ),
    ),
  };
}

async function main() {
  console.log(`Seeding TaskFlow demo for ${EXPECTED_EMAIL}`);
  console.log(`UID: ${UID}`);

  const tokens = loadFirebaseTokens();
  const accessToken = await getAccessToken(tokens);

  // Safety: confirm profile email matches.
  const profile = await firestore(accessToken, 'GET', USER_PATH);
  if (!profile?.fields?.email?.stringValue) {
    throw new Error(`User doc not found at ${USER_PATH}`);
  }
  const email = profile.fields.email.stringValue;
  if (email !== EXPECTED_EMAIL) {
    throw new Error(
      `Refusing to seed: profile email is "${email}", expected "${EXPECTED_EMAIL}"`,
    );
  }
  console.log(`Verified profile email: ${email}`);

  console.log('Clearing old subcollections...');
  for (const col of [
    `${USER_PATH}/projects`,
    `${USER_PATH}/tasks`,
    `${USER_PATH}/focusSessions`,
    `${USER_PATH}/notifications`,
    `${USER_PATH}/settings`,
  ]) {
    await clearCollection(accessToken, col);
  }

  const seed = buildSeedData();

  // Local streak sanity check (mirrors GoalsProvider rules).
  const focusGoal = 60;
  function dayKey(d) {
    return `${d.getFullYear()}-${d.getMonth()}-${d.getDate()}`;
  }
  function normalize(d) {
    return new Date(d.getFullYear(), d.getMonth(), d.getDate());
  }
  const dueByDay = new Map();
  const doneDueByDay = new Map();
  for (const t of seed.tasks) {
    if (!t.dueDate) continue;
    const key = dayKey(t.dueDate);
    dueByDay.set(key, (dueByDay.get(key) ?? 0) + 1);
    if (
      t.isCompleted &&
      t.completedAt &&
      dayKey(t.completedAt) === key
    ) {
      doneDueByDay.set(key, (doneDueByDay.get(key) ?? 0) + 1);
    }
  }
  const focusByDay = new Map();
  for (const f of seed.focusSessions) {
    const key = dayKey(f.time);
    focusByDay.set(key, (focusByDay.get(key) ?? 0) + f.durationMinutes);
  }
  function isStreakDay(offset) {
    const d = dayAt(offset, 12, 0);
    const key = dayKey(d);
    const goal = dueByDay.get(key) ?? 0;
    const done = doneDueByDay.get(key) ?? 0;
    const focus = focusByDay.get(key) ?? 0;
    const taskMet = goal === 0 || done >= goal;
    const focusMet = focus >= focusGoal;
    return taskMet && focusMet;
  }
  let streak = 0;
  let cursor = 0;
  if (!isStreakDay(0)) cursor = -1;
  while (isStreakDay(cursor)) {
    streak += 1;
    cursor -= 1;
  }
  console.log(
    `Expected current streak from seed rules: ${streak} day(s) ` +
      `(today=${isStreakDay(0)}, d-1=${isStreakDay(-1)}, d-2=${isStreakDay(-2)}, ` +
      `d-3=${isStreakDay(-3)}, d-4=${isStreakDay(-4)}, d-5=${isStreakDay(-5)})`,
  );

  console.log('Writing projects...');
  for (const p of seed.projects) {
    await setDoc(accessToken, `${USER_PATH}/projects/${p.id}`, projectFields(p));
  }

  console.log('Writing tasks...');
  for (const t of seed.tasks) {
    await setDoc(accessToken, `${USER_PATH}/tasks/${t.id}`, taskFields(t));
  }

  console.log('Writing focusSessions...');
  for (const f of seed.focusSessions) {
    await setDoc(
      accessToken,
      `${USER_PATH}/focusSessions/${f.id}`,
      focusFields(f),
    );
  }

  console.log('Writing notifications...');
  for (const n of seed.notifications) {
    await setDoc(
      accessToken,
      `${USER_PATH}/notifications/${n.id}`,
      notificationFields(n),
    );
  }

  console.log('Writing settings/userSettings...');
  await setDoc(
    accessToken,
    `${USER_PATH}/settings/userSettings`,
    settingsFields(seed.settings),
  );

  // Keep profile intact; only ensure hasSeenWelcome so demo skips onboarding if used.
  await setDoc(accessToken, USER_PATH, {
    email: str(EXPECTED_EMAIL),
    fullName: str(profile.fields.fullName?.stringValue ?? 'Duong Do Hoang'),
    avatarUrl: profile.fields.avatarUrl?.stringValue
      ? str(profile.fields.avatarUrl.stringValue)
      : str(
          'https://api.dicebear.com/7.x/avataaars/png?seed=Mint&backgroundColor=b6e3f4',
        ),
    hasSeenWelcome: bool(true),
    createdAt: profile.fields.createdAt ?? ts(new Date('2026-07-01T07:48:19Z')),
  });

  console.log('Done.');
  console.log(
    `Seeded ${seed.projects.length} projects, ${seed.tasks.length} tasks, ` +
      `${seed.focusSessions.length} focus sessions, ${seed.notifications.length} notifications.`,
  );
  console.log('Login with dohoangduong2708@gmail.com and hot-restart the app.');
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
