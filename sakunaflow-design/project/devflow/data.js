// DevFlow — 假資料（模擬真實開發者使用情境）
window.DF_DATA = {
  user: { name: '陳映丞', email: 'yingcheng@example.com' },

  projects: [
    { id: 'p1', name: 'SakunaFlow', color: '#8c52ff', status: 'active',
      tags: ['Flutter', 'Dart'], desc: '個人開發者任務管理 app', weekPomodoros: 12, activeTasks: 8 },
    { id: 'p2', name: '個人網站 v3', color: '#0075de', status: 'active',
      tags: ['Next.js', 'TypeScript'], desc: 'Portfolio 全面翻新', weekPomodoros: 5, activeTasks: 4 },
    { id: 'p3', name: 'HomeServer', color: '#2a9d99', status: 'paused',
      tags: ['Docker', 'Nginx', 'Linux'], desc: '家用伺服器基礎設施', weekPomodoros: 2, activeTasks: 3 },
  ],

  tasks: [
    { id: 't1', projectId: 'p1', title: '實作 SyncService push 機制', priority: 1,
      status: 'in_progress', dueLabel: '今天', est: 3, actual: 2, subtasksDone: 1, subtasksTotal: 2 },
    { id: 't2', projectId: 'p1', title: '設計 CalendarScreen UI', priority: 2,
      status: 'todo', dueLabel: '今天', est: 2, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't3', projectId: 'p1', title: '修復番茄鐘背景計時 bug', priority: 0,
      status: 'todo', dueLabel: '今天', est: 1, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't4', projectId: 'p2', title: '撰寫首頁 Hero 區塊', priority: 2,
      status: 'todo', dueLabel: '明天', est: 1, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't5', projectId: 'p2', title: '設定 SEO meta tags', priority: 3,
      status: 'done', dueLabel: null, est: 1, actual: 1, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't6', projectId: 'p3', title: '設定 Nginx reverse proxy', priority: 2,
      status: 'done', dueLabel: null, est: 2, actual: 2, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't7', projectId: 'p1', title: '撰寫 Drift schema migration', priority: 2,
      status: 'todo', dueLabel: '本週', est: 2, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't8', projectId: 'p1', title: 'iOS 通知適配', priority: 2,
      status: 'todo', dueLabel: '本週', est: 3, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't9', projectId: null, title: '訂機票（5月回台南）', priority: 2,
      status: 'todo', dueLabel: '今天', est: 0, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't10', projectId: null, title: '回覆牙醫預約訊息', priority: 3,
      status: 'todo', dueLabel: '今天', est: 0, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
    { id: 't11', projectId: null, title: '讀《原子習慣》第五章', priority: 3,
      status: 'done', dueLabel: null, est: 0, actual: 0, subtasksDone: 0, subtasksTotal: 0 },
  ],

  todayStats: { pomodoros: 2, focusMinutes: 50, completedTasks: 1, inProgressTasks: 1 },

  weekChart: [
    { label: '週一', count: 4 },
    { label: '週二', count: 7 },
    { label: '週三', count: 3 },
    { label: '週四', count: 6 },
    { label: '週五', count: 2 },
    { label: '週六', count: 0 },
    { label: '週日', count: 0 },
  ],

  // April 2026 calendar marks (date → array of colored dots)
  calendarMarks: {
    7:  [{ color: '#8c52ff', type: 'pomodoro' }, { color: '#0075de', type: 'pomodoro' }],
    8:  [{ color: '#8c52ff', type: 'pomodoro' }],
    14: [{ color: '#8c52ff', type: 'pomodoro' }, { color: '#8c52ff', type: 'pomodoro' }],
    15: [{ color: '#0075de', type: 'pomodoro' }],
    17: [{ color: '#8c52ff', type: 'task' }],
    18: [{ color: '#8c52ff', type: 'pomodoro' }, { color: '#2a9d99', type: 'pomodoro' }],
    19: [{ color: '#8c52ff', type: 'pomodoro' }],
    20: [{ color: '#8c52ff', type: 'pomodoro' }, { color: '#dd5b00', type: 'event' }],
    22: [{ color: '#0075de', type: 'task' }],
    25: [{ color: '#8c52ff', type: 'task' }, { color: '#0075de', type: 'task' }],
  },
};
