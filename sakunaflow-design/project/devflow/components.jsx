/* DevFlow — 所有共用元件 + 所有畫面 + Layout */
const { useState, useEffect, useRef } = React;

// ─── 優先級設定 ───────────────────────────────────────────────
const PRIO = {
  0: { l: 'P0', bg: '#ffeaea', c: '#d93838' },
  1: { l: 'P1', bg: '#fff3e0', c: '#dd5b00' },
  2: { l: 'P2', bg: '#f0f7ff', c: '#0075de' },
  3: { l: 'P3', bg: '#f5f5f5', c: '#888' },
};

// ─── 共用 UI 元件 ─────────────────────────────────────────────

function PriorityBadge({ priority, theme }) {
  const p = PRIO[priority] || PRIO[2];
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', padding: '1px 6px',
      borderRadius: theme.radius.pill + 'px', background: p.bg, color: p.c,
      fontSize: 11, fontWeight: 600, letterSpacing: '0.3px', flexShrink: 0 }}>
      {p.l}
    </span>
  );
}

function ProjectLabel({ projectId, theme }) {
  const proj = (window.DF_DATA.projects || []).find(p => p.id === projectId);
  if (!proj) return null;
  return (
    <span style={{ display: 'inline-flex', alignItems: 'center', gap: 4,
      fontSize: 12, color: theme.text.secondary }}>
      <span style={{ width: 6, height: 6, borderRadius: '50%',
        background: proj.color, display: 'inline-block', flexShrink: 0 }} />
      {proj.name}
    </span>
  );
}

function TaskCheckbox({ done, onToggle, theme, size = 20 }) {
  const [h, sH] = useState(false);
  return (
    <button onClick={onToggle} onMouseEnter={() => sH(true)} onMouseLeave={() => sH(false)}
      style={{ width: size, height: size, borderRadius: '50%', flexShrink: 0,
        border: done ? 'none' : `1.5px solid ${h ? theme.accent : theme.text.muted}`,
        background: done ? theme.accent : 'transparent', cursor: 'pointer',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        transition: 'all 0.15s', padding: 0 }}>
      {done && <svg width="10" height="8" viewBox="0 0 10 8" fill="none">
        <path d="M1 4L3.5 6.5L9 1" stroke="white" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round"/>
      </svg>}
    </button>
  );
}

function TaskItem({ task, theme, draggable, onDragStart, onDragOver, onDrop, dragOver }) {
  const [done, setDone] = useState(task.status === 'done');
  const [hov, setHov] = useState(false);
  const proj = (window.DF_DATA.projects || []).find(p => p.id === task.projectId);
  // Left border colour based on priority (only when not done)
  const accentColor = !done && task.priority === 0 ? '#d93838'
    : !done && task.priority === 1 ? '#dd5b00' : 'transparent';
  return (
    <div draggable={!!draggable} onDragStart={onDragStart} onDragOver={onDragOver} onDrop={onDrop}
      onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{ display: 'flex', alignItems: 'flex-start', gap: 10,
        padding: '10px 12px', paddingLeft: accentColor !== 'transparent' ? 9 : 12,
        borderBottom: `1px solid ${theme.border}`,
        borderLeft: `3px solid ${accentColor}`,
        opacity: done ? 0.42 : 1, transition: 'opacity .2s, background .1s',
        background: dragOver ? `${theme.accent}09` : 'transparent',
        cursor: draggable && hov ? 'grab' : 'default' }}>
      {/* Drag handle — fades in on hover */}
      {draggable && (
        <div style={{ opacity: hov ? 0.28 : 0, transition: 'opacity .15s', flexShrink: 0,
          fontSize: 13, paddingTop: 3, userSelect: 'none', cursor: 'grab' }}>⣿</div>
      )}
      <TaskCheckbox done={done} onToggle={() => setDone(!done)} theme={theme} />
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ fontSize: 14, fontWeight: 500, color: theme.text.primary,
          textDecoration: done ? 'line-through' : 'none',
          overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
          {task.title}
        </div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 3, flexWrap: 'wrap' }}>
          {proj && (
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3,
              fontSize: 12, color: theme.text.secondary }}>
              <span style={{ width: 5, height: 5, borderRadius: '50%',
                background: proj.color, display: 'inline-block' }} />
              {proj.name}
            </span>
          )}
          {task.dueLabel && (
            <span style={{ fontSize: 12, color: task.dueLabel === '今天' ? '#d93838' : theme.text.muted }}>
              {task.dueLabel}
            </span>
          )}
          {task.subtasksTotal > 0 && (
            <span style={{ fontSize: 12, color: theme.text.muted }}>
              {task.subtasksDone}/{task.subtasksTotal}
            </span>
          )}
        </div>
      </div>
      <PriorityBadge priority={task.priority} theme={theme} />
    </div>
  );
}

function SectionHeader({ label, count, theme, action }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '14px 0 8px', borderBottom: `1px solid ${theme.border}` }}>
      <span style={{ fontSize: 11, fontWeight: 700, color: theme.text.muted,
        textTransform: 'uppercase', letterSpacing: '0.8px' }}>
        {label}
        {count !== undefined && (
          <span style={{ marginLeft: 6, background: theme.border, color: theme.text.secondary,
            borderRadius: 10, padding: '1px 6px', fontWeight: 500 }}>{count}</span>
        )}
      </span>
      {action && (
        <button onClick={action.fn} style={{ fontSize: 12, color: theme.accent,
          background: 'none', border: 'none', cursor: 'pointer', fontFamily: 'inherit' }}>
          {action.label}
        </button>
      )}
    </div>
  );
}

function PrimaryBtn({ children, onClick, theme, small, style: extra }) {
  const [h, sH] = useState(false);
  return (
    <button onClick={onClick} onMouseEnter={() => sH(true)} onMouseLeave={() => sH(false)}
      style={{ background: h ? theme.accentDark : theme.accent, color: '#fff',
        border: 'none', cursor: 'pointer', padding: small ? '5px 12px' : '8px 16px',
        borderRadius: theme.radius.sm + 'px', fontSize: small ? 13 : 14,
        fontWeight: 600, fontFamily: 'inherit', transition: 'background .15s', ...extra }}>
      {children}
    </button>
  );
}

// ─── 今日畫面 ──────────────────────────────────────────────────

function TodayScreen({ theme }) {
  const { tasks, todayStats } = window.DF_DATA;
  const [localTasks, setLocalTasks] = useState(tasks);
  const [quickAdd, setQuickAdd] = useState('');
  const [adding, setAdding] = useState(false);
  const [dragIdx, setDragIdx] = useState(null);
  const [overIdx, setOverIdx] = useState(null);
  const inProgress = localTasks.filter(t => t.status === 'in_progress');
  const todayTodo  = localTasks.filter(t => t.dueLabel === '今天' && t.status === 'todo');
  const tomorrow   = localTasks.filter(t => t.dueLabel === '明天' && t.status !== 'done');
  const handleDrop = (dropIdx) => {
    if (dragIdx === null || dragIdx === dropIdx) { setDragIdx(null); setOverIdx(null); return; }
    const todayIds = localTasks.filter(t => t.dueLabel === '今天' && t.status === 'todo').map(t => t.id);
    const reordered = [...todayIds];
    const [moved] = reordered.splice(dragIdx, 1);
    reordered.splice(dropIdx, 0, moved);
    const others = localTasks.filter(t => !(t.dueLabel === '今天' && t.status === 'todo'));
    setLocalTasks([...reordered.map(id => localTasks.find(t => t.id === id)), ...others]);
    setDragIdx(null); setOverIdx(null);
  };
  const handleQuickAdd = () => {
    if (!quickAdd.trim()) { setAdding(false); return; }
    const newTask = { id: 't_' + Date.now(), projectId: null, title: quickAdd.trim(),
      priority: 2, status: 'todo', dueLabel: '今天', est: 0, actual: 0, subtasksDone: 0, subtasksTotal: 0 };
    setLocalTasks(prev => [...prev, newTask]);
    setQuickAdd(''); setAdding(false);
  };

  const StatCard = ({ v, l }) => (
    <div style={{ background: theme.surfaceAlt, borderRadius: theme.radius.md + 'px',
      padding: '14px 16px', flex: 1, border: `1px solid ${theme.border}` }}>
      <div style={{ fontSize: 22, fontWeight: 700, color: theme.text.primary }}>{v}</div>
      <div style={{ fontSize: 12, color: theme.text.muted, marginTop: 2 }}>{l}</div>
    </div>
  );

  return (
    <div style={{ padding: '28px 36px', maxWidth: 700, fontFamily: theme.font }}>
      <div style={{ marginBottom: 20 }}>
        <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px' }}>今日</div>
        <div style={{ fontSize: 13, color: theme.text.muted, marginTop: 3 }}>2026年4月20日　週一</div>
      </div>
      <div style={{ display: 'flex', gap: 10, marginBottom: 28 }}>
        <StatCard v={todayStats.completedTasks} l="今日完成" />
        <StatCard v={todayStats.inProgressTasks} l="進行中" />
        <StatCard v={8} l="本週完成" />
      </div>
      {inProgress.length > 0 && (
        <div style={{ marginBottom: 20 }}>
          <SectionHeader label="進行中" count={inProgress.length} theme={theme} />
          {inProgress.map(t => <TaskItem key={t.id} task={t} theme={theme} />)}
        </div>
      )}
      <div style={{ marginBottom: 20 }}>
        <SectionHeader label="今日待辦" count={todayTodo.length} theme={theme}
          action={{ label: '＋ 新增', fn: () => {} }} />
        {todayTodo.length === 0
          ? <div style={{ padding: '24px 0', textAlign: 'center', color: theme.text.muted, fontSize: 14 }}>今天沒有待辦事項 🎉</div>
          : todayTodo.map((t, i) => (
            <TaskItem key={t.id} task={t} theme={theme} draggable
              dragOver={overIdx === i}
              onDragStart={() => setDragIdx(i)}
              onDragOver={e => { e.preventDefault(); setOverIdx(i); }}
              onDrop={() => handleDrop(i)} />
          ))}
      </div>
      {tomorrow.length > 0 && (
        <div>
          <SectionHeader label="明日" count={tomorrow.length} theme={theme} />
          {tomorrow.map(t => <TaskItem key={t.id} task={t} theme={theme} />)}
        </div>
      )}
      {/* Quick add row */}
      <div style={{ marginTop: 20, paddingTop: 8 }}>
        {adding ? (
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <input autoFocus value={quickAdd} onChange={e => setQuickAdd(e.target.value)}
              onKeyDown={e => { if (e.key === 'Enter') handleQuickAdd(); if (e.key === 'Escape') { setAdding(false); setQuickAdd(''); } }}
              onBlur={handleQuickAdd}
              placeholder="輸入任務標題，按 Enter 新增…"
              style={{ flex: 1, padding: '8px 12px', borderRadius: theme.radius.sm + 'px',
                border: `1.5px solid ${theme.accent}`, outline: 'none', fontSize: 14,
                color: theme.text.primary, fontFamily: theme.font,
                background: 'white', boxShadow: `0 0 0 3px ${theme.accent}20` }} />
            <button onClick={() => { setAdding(false); setQuickAdd(''); }}
              style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 18, color: theme.text.muted }}>✕</button>
          </div>
        ) : (
          <button onClick={() => setAdding(true)}
            style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '6px 0',
              background: 'none', border: 'none', cursor: 'pointer',
              color: theme.text.muted, fontSize: 14, fontFamily: theme.font, opacity: 0.7,
              transition: 'opacity .15s' }}
            onMouseEnter={e => e.currentTarget.style.opacity = 1}
            onMouseLeave={e => e.currentTarget.style.opacity = 0.7}>
            <span style={{ width: 20, height: 20, borderRadius: '50%', border: `1.5px dashed ${theme.text.muted}`,
              display: 'inline-flex', alignItems: 'center', justifyContent: 'center', fontSize: 14 }}>＋</span>
            新增任務
          </button>
        )}
      </div>
    </div>
  );
}

// ─── 番茄鐘畫面 ────────────────────────────────────────────────

function PomodoroScreen({ theme, interactive = true }) {
  const TOTAL = 25 * 60;
  const [phase, setPhase] = useState('ready');
  const [secs, setSecs] = useState(TOTAL);
  const startAt = useRef(null);
  const startSecs = useRef(TOTAL);
  const task = window.DF_DATA.tasks[0];
  const proj = window.DF_DATA.projects.find(p => p.id === task.projectId);

  useEffect(() => {
    if (phase !== 'working') return;
    const id = setInterval(() => {
      const elapsed = (Date.now() - startAt.current) / 1000;
      const left = Math.max(0, startSecs.current - elapsed);
      setSecs(Math.round(left));
      if (left <= 0) { setPhase('done'); clearInterval(id); }
    }, 400);
    return () => clearInterval(id);
  }, [phase]);

  const doStart = () => { startAt.current = Date.now(); startSecs.current = secs; setPhase('working'); };
  const doPause = () => setPhase('paused');
  const doResume = () => { startAt.current = Date.now(); startSecs.current = secs; setPhase('working'); };
  const doAbandon = () => { setPhase('ready'); setSecs(TOTAL); };

  const mm = String(Math.floor(secs / 60)).padStart(2, '0');
  const ss = String(secs % 60).padStart(2, '0');
  const prog = 1 - secs / TOTAL;
  const R = 110, C = 2 * Math.PI * R;
  const phaseLabel = { ready: '就緒', working: '工作中', paused: '暫停', done: '完成！' }[phase];

  return (
    <div style={{ padding: '28px 36px', display: 'flex', flexDirection: 'column',
      alignItems: 'center', gap: 26, fontFamily: theme.font }}>
      <div style={{ width: '100%' }}>
        <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px' }}>番茄鐘</div>
        <div style={{ fontSize: 13, color: theme.text.muted, marginTop: 3 }}>今日已完成 2 個 · 本週共 14 個</div>
      </div>
      {/* Ring */}
      <div style={{ position: 'relative', width: 256, height: 256 }}>
        <svg width="256" height="256" viewBox="0 0 256 256" style={{ transform: 'rotate(-90deg)' }}>
          <circle cx="128" cy="128" r={R} fill="none" stroke={theme.border} strokeWidth="10" />
          <circle cx="128" cy="128" r={R} fill="none" stroke={theme.pomodoroAccent} strokeWidth="10"
            strokeDasharray={C} strokeDashoffset={C * (1 - prog)} strokeLinecap="round"
            style={{ transition: 'stroke-dashoffset .4s linear' }} />
        </svg>
        <div style={{ position: 'absolute', inset: 0, display: 'flex',
          flexDirection: 'column', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ fontFamily: "'JetBrains Mono',monospace", fontSize: 46,
            fontWeight: 500, color: theme.text.primary, letterSpacing: '-1px', lineHeight: 1 }}>
            {mm}:{ss}
          </div>
          <div style={{ fontSize: 12, color: theme.text.muted, marginTop: 6, fontWeight: 500 }}>{phaseLabel}</div>
        </div>
      </div>
      {/* Session dots */}
      <div style={{ display: 'flex', gap: 6, alignItems: 'center' }}>
        {[0,1,2,3].map(i => (
          <div key={i} style={{ width: 8, height: 8, borderRadius: '50%',
            background: i < 2 ? theme.pomodoroAccent : theme.border }} />
        ))}
        <span style={{ fontSize: 12, color: theme.text.muted, marginLeft: 4 }}>今日第 3 個</span>
      </div>
      {/* Current task */}
      <div style={{ width: '100%', background: theme.surfaceAlt,
        borderRadius: theme.radius.lg + 'px', padding: '14px 18px', border: `1px solid ${theme.border}` }}>
        <div style={{ fontSize: 11, color: theme.text.muted, marginBottom: 6,
          fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.5px' }}>目前任務</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <span style={{ width: 8, height: 8, borderRadius: '50%', background: proj?.color, flexShrink: 0 }} />
          <div style={{ fontSize: 14, fontWeight: 600, color: theme.text.primary }}>{task.title}</div>
        </div>
        <div style={{ marginTop: 6, display: 'flex', gap: 12, fontSize: 12, color: theme.text.secondary }}>
          <span>{proj?.name}</span>
          <span>🍅 {task.actual}/{task.est}</span>
        </div>
      </div>
      {/* Controls */}
      <div style={{ display: 'flex', gap: 10 }}>
        {phase === 'ready'   && <PrimaryBtn theme={theme} onClick={doStart}>▶ 開始專注</PrimaryBtn>}
        {phase === 'working' && <>
          <PrimaryBtn theme={theme} onClick={doPause}>⏸ 暫停</PrimaryBtn>
          <button onClick={doAbandon} style={{ padding: '8px 16px', borderRadius: theme.radius.sm + 'px',
            border: `1px solid ${theme.border}`, background: 'none', cursor: 'pointer',
            fontSize: 14, color: theme.text.secondary, fontFamily: 'inherit' }}>放棄</button>
        </>}
        {phase === 'paused'  && <>
          <PrimaryBtn theme={theme} onClick={doResume}>▶ 繼續</PrimaryBtn>
          <button onClick={doAbandon} style={{ padding: '8px 16px', borderRadius: theme.radius.sm + 'px',
            border: `1px solid ${theme.border}`, background: 'none', cursor: 'pointer',
            fontSize: 14, color: theme.text.secondary, fontFamily: 'inherit' }}>放棄</button>
        </>}
        {phase === 'done'    && <PrimaryBtn theme={theme} onClick={() => { setPhase('ready'); setSecs(5 * 60); }}>☕ 短休 5 分鐘</PrimaryBtn>}
      </div>

      {/* Completion dialog */}
      {phase === 'done' && (
        <CompletionNote theme={theme} onDone={() => { setPhase('ready'); setSecs(5 * 60); }} />
      )}
    </div>
  );
}

function CompletionNote({ theme, onDone }) {
  const [note, setNote] = useState('');
  const [saved, setSaved] = useState(false);
  const handleSave = () => { setSaved(true); setTimeout(onDone, 800); };
  return (
    <div style={{ width: '100%', background: theme.surfaceAlt, borderRadius: theme.radius.lg + 'px',
      padding: '18px 20px', border: `1px solid ${theme.border}`,
      boxShadow: theme.cardShadow, animation: 'fadeSlideUp .3s ease' }}>
      <style>{`@keyframes fadeSlideUp { from { opacity:0; transform:translateY(8px); } to { opacity:1; transform:translateY(0); } }`}</style>
      <div style={{ fontSize: 15, fontWeight: 600, color: theme.text.primary, marginBottom: 4 }}>
        🎉 番茄鐘完成！
      </div>
      <div style={{ fontSize: 13, color: theme.text.secondary, marginBottom: 14 }}>
        記一筆這段時間做了什麼（可略過）
      </div>
      {!saved ? <>
        <input value={note} onChange={e => setNote(e.target.value)}
          onKeyDown={e => e.key === 'Enter' && handleSave()}
          placeholder="例：完成了 sync queue flush 邏輯…"
          style={{ width: '100%', padding: '8px 12px', borderRadius: theme.radius.sm + 'px',
            border: `1px solid ${theme.border}`, outline: 'none', fontSize: 14,
            color: theme.text.primary, fontFamily: 'inherit', background: 'white',
            marginBottom: 12 }} />
        <div style={{ display: 'flex', gap: 8 }}>
          <PrimaryBtn theme={theme} onClick={handleSave} small>記錄並開始短休</PrimaryBtn>
          <button onClick={onDone} style={{ padding: '5px 14px', borderRadius: theme.radius.sm + 'px',
            border: `1px solid ${theme.border}`, background: 'none', cursor: 'pointer',
            fontSize: 13, color: theme.text.secondary, fontFamily: 'inherit' }}>略過</button>
        </div>
      </> : (
        <div style={{ fontSize: 14, color: '#1aae39', fontWeight: 500 }}>✓ 已記錄，準備短休…</div>
      )}
    </div>
  );
}

// ─── 月曆畫面 ──────────────────────────────────────────────────

function CalendarScreen({ theme }) {
  const [selected, setSelected] = useState(20);
  const marks = window.DF_DATA.calendarMarks;
  const WD = ['一','二','三','四','五','六','日'];
  // April 2026: April 1 = Wednesday → offset 2 (Mon=0)
  const firstOffset = 2, totalDays = 30;
  const cells = [];
  for (let i = 0; i < firstOffset; i++) cells.push(null);
  for (let d = 1; d <= totalDays; d++) cells.push(d);
  while (cells.length % 7 !== 0) cells.push(null);
  const today = 20;

  return (
    <div style={{ padding: '28px 36px', maxWidth: 740, fontFamily: theme.font }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 20 }}>
        <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px' }}>月曆</div>
        <div style={{ display: 'flex', gap: 4 }}>
          {['月','週','日'].map(v => (
            <button key={v} style={{ padding: '4px 10px',
              borderRadius: theme.radius.pill + 'px',
              background: v === '月' ? theme.accent : 'transparent',
              color: v === '月' ? '#fff' : theme.text.secondary,
              border: `1px solid ${v === '月' ? theme.accent : theme.border}`,
              cursor: 'pointer', fontSize: 12, fontFamily: 'inherit' }}>{v}</button>
          ))}
        </div>
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 14 }}>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 18, color: theme.text.secondary }}>‹</button>
        <span style={{ fontSize: 16, fontWeight: 600, color: theme.text.primary }}>2026年 4月</span>
        <button style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 18, color: theme.text.secondary }}>›</button>
        <button style={{ marginLeft: 6, padding: '3px 8px', borderRadius: theme.radius.sm + 'px',
          border: `1px solid ${theme.border}`, background: 'none', cursor: 'pointer',
          fontSize: 12, color: theme.text.secondary, fontFamily: 'inherit' }}>今天</button>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 2, marginBottom: 4 }}>
        {WD.map(d => (
          <div key={d} style={{ textAlign: 'center', fontSize: 11, fontWeight: 600,
            color: theme.text.muted, padding: '4px 0' }}>{d}</div>
        ))}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 3 }}>
        {cells.map((day, i) => !day ? <div key={`e${i}`} /> : (
          <div key={day} onClick={() => setSelected(day)} style={{
            minHeight: 60, padding: '5px 6px', borderRadius: theme.radius.md + 'px', cursor: 'pointer',
            background: selected === day ? `${theme.accent}14` : day === today ? `${theme.accent}08` : 'transparent',
            border: day === today ? `1.5px solid ${theme.accent}` : selected === day ? `1px solid ${theme.accent}40` : `1px solid ${theme.border}`,
            transition: 'background .1s',
          }}>
            <div style={{ display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
              width: 22, height: 22, borderRadius: '50%',
              background: day === today ? theme.accent : 'transparent',
              color: day === today ? '#fff' : theme.text.primary,
              fontSize: 12, fontWeight: day === today ? 700 : 400 }}>{day}</div>
            {(marks[day] || []).length > 0 && (
              <div style={{ display: 'flex', gap: 2, marginTop: 3, flexWrap: 'wrap' }}>
                {(marks[day] || []).slice(0, 4).map((m, mi) => (
                  <div key={mi} style={{ width: 5, height: 5, borderRadius: '50%', background: m.color }} />
                ))}
              </div>
            )}
          </div>
        ))}
      </div>
      {selected && (marks[selected] || []).length > 0 && (
        <div style={{ marginTop: 16, padding: '12px 16px', background: theme.surfaceAlt,
          borderRadius: theme.radius.lg + 'px', border: `1px solid ${theme.border}` }}>
          <div style={{ fontSize: 13, fontWeight: 600, color: theme.text.primary, marginBottom: 8 }}>
            4月{selected}日
          </div>
          {(marks[selected] || []).map((m, i) => (
            <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8,
              padding: '3px 0', fontSize: 13, color: theme.text.secondary }}>
              <div style={{ width: 7, height: 7, borderRadius: '50%', background: m.color }} />
              <span>{m.type === 'pomodoro' ? '番茄鐘記錄' : m.type === 'task' ? '任務截止' : '行程事件'}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ─── 專案詳情畫面 ─────────────────────────────────────────────

function ProjectDetailView({ theme, project: p, tasks, onBack }) {
  const [adding, setAdding] = useState(false);
  const [newTask, setNewTask] = useState('');
  const [localTasks, setLocalTasks] = useState(tasks.filter(t => t.projectId === p.id));
  const todo      = localTasks.filter(t => t.status !== 'done');
  const done      = localTasks.filter(t => t.status === 'done');
  const SC = { active: { bg: '#e8f8ee', c: '#1aae39' }, paused: { bg: '#fff3e0', c: '#dd5b00' }, archived: { bg: '#f5f5f5', c: '#888' } };
  const sc = SC[p.status] || SC.active;
  const handleAdd = () => {
    if (!newTask.trim()) { setAdding(false); return; }
    setLocalTasks(prev => [...prev, { id: 't_' + Date.now(), projectId: p.id, title: newTask.trim(),
      priority: 2, status: 'todo', dueLabel: null, est: 0, actual: 0, subtasksDone: 0, subtasksTotal: 0 }]);
    setNewTask(''); setAdding(false);
  };
  return (
    <div style={{ padding: '28px 36px', fontFamily: theme.font, maxWidth: 700 }}>
      {/* Back */}
      <button onClick={onBack} style={{ display: 'flex', alignItems: 'center', gap: 4, background: 'none',
        border: 'none', cursor: 'pointer', fontSize: 13, color: theme.text.muted, fontFamily: theme.font,
        marginBottom: 20, padding: 0 }}
        onMouseEnter={e => e.currentTarget.style.color = theme.accent}
        onMouseLeave={e => e.currentTarget.style.color = theme.text.muted}>
        ← 所有專案
      </button>
      {/* Header */}
      <div style={{ display: 'flex', alignItems: 'flex-start', gap: 16, marginBottom: 20 }}>
        <div style={{ width: 5, height: 52, borderRadius: 4, background: p.color, flexShrink: 0 }} />
        <div style={{ flex: 1 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
            <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px' }}>{p.name}</div>
            <span style={{ padding: '2px 8px', borderRadius: theme.radius.pill + 'px',
              background: sc.bg, color: sc.c, fontSize: 11, fontWeight: 600 }}>
              {{active:'進行中',paused:'暫停',archived:'已封存'}[p.status]}
            </span>
          </div>
          <div style={{ fontSize: 13, color: theme.text.secondary, marginTop: 4 }}>{p.desc}</div>
          <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
            {p.tags.map(t => (
              <span key={t} style={{ padding: '2px 8px', background: theme.surfaceAlt,
                borderRadius: theme.radius.sm + 'px', fontSize: 12, color: theme.text.secondary,
                fontFamily: "'JetBrains Mono',monospace" }}>{t}</span>
            ))}
          </div>
        </div>
        <div style={{ textAlign: 'center', flexShrink: 0 }}>
          <div style={{ fontSize: 22, fontWeight: 700, color: theme.text.primary }}>{todo.length}</div>
          <div style={{ fontSize: 11, color: theme.text.muted }}>待辦任務</div>
        </div>
      </div>
      {/* Todo tasks */}
      <SectionHeader label="待辦" count={todo.length} theme={theme}
        action={{ label: '＋ 新增', fn: () => setAdding(true) }} />
      {todo.length === 0 && !adding && (
        <div style={{ padding: '20px 0', textAlign: 'center', color: theme.text.muted, fontSize: 14 }}>
          這個專案目前沒有待辦任務
        </div>
      )}
      {todo.map(t => <TaskItem key={t.id} task={t} theme={theme} />)}
      {/* Quick add */}
      {adding && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '10px 12px',
          borderBottom: `1px solid ${theme.border}` }}>
          <input autoFocus value={newTask} onChange={e => setNewTask(e.target.value)}
            onKeyDown={e => { if (e.key === 'Enter') handleAdd(); if (e.key === 'Escape') { setAdding(false); setNewTask(''); } }}
            onBlur={handleAdd}
            placeholder="輸入任務標題…"
            style={{ flex: 1, padding: '6px 10px', borderRadius: theme.radius.sm + 'px',
              border: `1.5px solid ${theme.accent}`, outline: 'none', fontSize: 14,
              color: theme.text.primary, fontFamily: theme.font, background: 'white' }} />
        </div>
      )}
      {/* Done tasks */}
      {done.length > 0 && (
        <div style={{ marginTop: 24 }}>
          <SectionHeader label="已完成" count={done.length} theme={theme} />
          {done.map(t => <TaskItem key={t.id} task={t} theme={theme} />)}
        </div>
      )}
    </div>
  );
}

// ─── 專案畫面 ──────────────────────────────────────────────────

function ProjectsScreen({ theme }) {
  const { projects, tasks } = window.DF_DATA;
  const [selectedProject, setSelectedProject] = useState(null);
  const STATUS_LABEL = { active: '進行中', paused: '暫停', archived: '已封存' };
  const STATUS_COLOR = { active: { bg: '#e8f8ee', c: '#1aae39' }, paused: { bg: '#fff3e0', c: '#dd5b00' }, archived: { bg: '#f5f5f5', c: '#888' } };

  if (selectedProject) {
    return <ProjectDetailView theme={theme} project={selectedProject} tasks={tasks} onBack={() => setSelectedProject(null)} />;
  }

  return (
    <div style={{ padding: '28px 36px', fontFamily: theme.font }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 24 }}>
        <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px' }}>專案</div>
        <PrimaryBtn theme={theme} small>＋ 新增專案</PrimaryBtn>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {projects.map(p => {
          const ptasks = tasks.filter(t => t.projectId === p.id && t.status !== 'done');
          const sc = STATUS_COLOR[p.status] || STATUS_COLOR.active;
          return (
            <div key={p.id} onClick={() => setSelectedProject(p)}
              style={{ background: theme.bg, border: `1px solid ${theme.border}`,
              borderRadius: theme.radius.lg + 'px', padding: '18px 20px',
              boxShadow: theme.cardShadow, display: 'flex', gap: 16, alignItems: 'flex-start',
              cursor: 'pointer', transition: 'box-shadow .15s, transform .1s' }}
              onMouseEnter={e => { e.currentTarget.style.boxShadow = '0 4px 20px rgba(0,0,0,0.1)'; e.currentTarget.style.transform = 'translateY(-1px)'; }}
              onMouseLeave={e => { e.currentTarget.style.boxShadow = theme.cardShadow; e.currentTarget.style.transform = 'none'; }}>
              <div style={{ width: 4, minHeight: 52, borderRadius: 4,
                background: p.color, flexShrink: 0 }} />
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexWrap: 'wrap' }}>
                  <div style={{ fontSize: 15, fontWeight: 600, color: theme.text.primary }}>{p.name}</div>
                  <span style={{ padding: '2px 8px', borderRadius: theme.radius.pill + 'px',
                    background: sc.bg, color: sc.c, fontSize: 11, fontWeight: 600 }}>
                    {STATUS_LABEL[p.status]}
                  </span>
                </div>
                <div style={{ fontSize: 13, color: theme.text.secondary, marginTop: 4 }}>{p.desc}</div>
                <div style={{ display: 'flex', gap: 6, marginTop: 10, flexWrap: 'wrap' }}>
                  {p.tags.map(t => (
                    <span key={t} style={{ padding: '2px 8px', background: theme.surfaceAlt,
                      borderRadius: theme.radius.sm + 'px', fontSize: 12,
                      color: theme.text.secondary, fontFamily: "'JetBrains Mono',monospace" }}>{t}</span>
                  ))}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 20, flexShrink: 0, paddingTop: 4 }}>
                <div style={{ textAlign: 'center' }}>
                  <div style={{ fontSize: 18, fontWeight: 700, color: theme.text.primary }}>{ptasks.length}</div>
                  <div style={{ fontSize: 11, color: theme.text.muted }}>進行中任務</div>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

// ─── 統計畫面 ──────────────────────────────────────────────────

function StatsScreen({ theme }) {
  const { todayStats, weekChart, projects } = window.DF_DATA;
  const maxCount = Math.max(...weekChart.map(d => d.count), 1);
  const todayIdx = 4; // Friday

  return (
    <div style={{ padding: '28px 36px', maxWidth: 740, fontFamily: theme.font }}>
      <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px', marginBottom: 24 }}>統計</div>
      {/* Today */}
      <div style={{ fontSize: 11, fontWeight: 700, color: theme.text.muted, textTransform: 'uppercase', letterSpacing: '0.8px', marginBottom: 12 }}>今日</div>
      <div style={{ display: 'flex', gap: 10, marginBottom: 32 }}>
        {[
          { v: todayStats.completedTasks, l: '完成任務', c: '#1aae39' },
          { v: todayStats.inProgressTasks, l: '進行中', c: '#dd5b00' },
          { v: 8, l: '本週完成', c: theme.accent },
        ].map(({ v, l, c }) => (
          <div key={l} style={{ flex: 1, background: theme.surfaceAlt, borderRadius: theme.radius.lg + 'px',
            padding: '14px 16px', border: `1px solid ${theme.border}` }}>
            <div style={{ fontSize: 22, fontWeight: 700, color: c }}>{v}</div>
            <div style={{ fontSize: 12, color: theme.text.muted, marginTop: 2 }}>{l}</div>
          </div>
        ))}
      </div>
      {/* Week task chart */}
      <div style={{ fontSize: 11, fontWeight: 700, color: theme.text.muted, textTransform: 'uppercase', letterSpacing: '0.8px', marginBottom: 14 }}>本週任務完成趨勢</div>
      <div style={{ display: 'flex', gap: 8, alignItems: 'flex-end', height: 100, marginBottom: 32 }}>
        {[{label:'週一',count:3},{label:'週二',count:5},{label:'週三',count:2},{label:'週四',count:4},{label:'週五',count:1},{label:'週六',count:0},{label:'週日',count:0}].map(({ label, count }, i) => (
          <div key={label} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4 }}>
            <div style={{ fontSize: 11, fontWeight: 600, color: count > 0 ? theme.text.primary : 'transparent' }}>{count}</div>
            <div style={{ width: '100%', borderRadius: theme.radius.sm + 'px',
              background: i === todayIdx ? theme.accent : `${theme.accent}38`,
              height: Math.max(4, (count / 5) * 64) + 'px', minHeight: 4,
              transition: 'height .3s' }} />
            <div style={{ fontSize: 11, color: i === todayIdx ? theme.accent : theme.text.muted,
              fontWeight: i === todayIdx ? 700 : 400 }}>{label.slice(1)}</div>
          </div>
        ))}
      </div>
      {/* Projects ranking */}
      <div style={{ fontSize: 11, fontWeight: 700, color: theme.text.muted, textTransform: 'uppercase', letterSpacing: '0.8px', marginBottom: 12 }}>進行中專案</div>
      {projects.filter(p => p.status === 'active')
        .map((p, i) => (
          <div key={p.id} style={{ display: 'flex', alignItems: 'center', gap: 12,
            padding: '10px 0', borderBottom: `1px solid ${theme.border}` }}>
            <div style={{ fontSize: 13, fontWeight: 600, color: theme.text.muted, width: 20, textAlign: 'right' }}>{i + 1}</div>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: p.color }} />
            <div style={{ flex: 1, fontSize: 14, color: theme.text.primary }}>{p.name}</div>
            <div style={{ fontSize: 14, fontWeight: 600, color: theme.text.primary }}>{p.activeTasks} 個任務</div>
            <div style={{ width: 80, height: 4, background: theme.border, borderRadius: 2 }}>
              <div style={{ width: (p.activeTasks / 10 * 100) + '%', height: '100%',
                background: p.color, borderRadius: 2 }} />
            </div>
          </div>
        ))}
    </div>
  );
}

// ─── 設定畫面 ──────────────────────────────────────────────────

function SettingsScreen({ theme }) {
  const [workDur, setWorkDur] = useState(25);
  const [autoStart, setAutoStart] = useState(false);
  const [sound, setSound] = useState(true);
  const [themeMode, setThemeMode] = useState('system');

  const Toggle = ({ val, onChange }) => (
    <button onClick={() => onChange(!val)} style={{ width: 38, height: 22, borderRadius: 11,
      background: val ? theme.accent : theme.border, border: 'none', cursor: 'pointer',
      position: 'relative', transition: 'background .2s', flexShrink: 0 }}>
      <span style={{ position: 'absolute', top: 2, left: val ? 18 : 2, width: 18, height: 18,
        borderRadius: '50%', background: 'white', transition: 'left .2s',
        boxShadow: '0 1px 3px rgba(0,0,0,.25)' }} />
    </button>
  );
  const Row = ({ label, children }) => (
    <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '12px 0', borderBottom: `1px solid ${theme.border}` }}>
      <span style={{ fontSize: 14, color: theme.text.primary }}>{label}</span>
      {children}
    </div>
  );
  const Sec = ({ label }) => (
    <div style={{ fontSize: 11, fontWeight: 700, color: theme.text.muted,
      textTransform: 'uppercase', letterSpacing: '0.8px', padding: '20px 0 4px' }}>{label}</div>
  );

  return (
    <div style={{ padding: '28px 36px', maxWidth: 520, fontFamily: theme.font }}>
      <div style={{ fontSize: 24, fontWeight: 700, color: theme.text.primary, letterSpacing: '-0.5px', marginBottom: 4 }}>設定</div>
      <Sec label="帳號" />
      <Row label={window.DF_DATA.user.name}>
        <span style={{ fontSize: 13, color: theme.text.muted }}>yingcheng@example.com</span>
      </Row>
      <Row label="">
        <button style={{ padding: '5px 14px', borderRadius: theme.radius.sm + 'px',
          border: `1px solid ${theme.border}`, background: 'none', cursor: 'pointer',
          fontSize: 13, color: '#d93838', fontFamily: 'inherit' }}>登出</button>
      </Row>
      <Sec label="番茄鐘" />
      <Row label="工作時長">
        <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
          <button onClick={() => setWorkDur(d => Math.max(5, d - 5))}
            style={{ width: 26, height: 26, borderRadius: '50%', background: theme.surfaceAlt,
              border: `1px solid ${theme.border}`, cursor: 'pointer', fontSize: 16 }}>−</button>
          <span style={{ fontSize: 14, fontWeight: 600, color: theme.text.primary, width: 32, textAlign: 'center' }}>{workDur}m</span>
          <button onClick={() => setWorkDur(d => Math.min(60, d + 5))}
            style={{ width: 26, height: 26, borderRadius: '50%', background: theme.surfaceAlt,
              border: `1px solid ${theme.border}`, cursor: 'pointer', fontSize: 16 }}>+</button>
        </div>
      </Row>
      <Row label="完成音效"><Toggle val={sound} onChange={setSound} /></Row>
      <Row label="自動開始下一階段"><Toggle val={autoStart} onChange={setAutoStart} /></Row>
      <Sec label="外觀" />
      <Row label="主題模式">
        <div style={{ display: 'flex', gap: 4 }}>
          {[['light','淺色'],['dark','深色'],['system','跟隨系統']].map(([m, l]) => (
            <button key={m} onClick={() => setThemeMode(m)} style={{ padding: '4px 10px',
              borderRadius: theme.radius.sm + 'px',
              background: themeMode === m ? theme.accent : 'transparent',
              color: themeMode === m ? '#fff' : theme.text.secondary,
              border: `1px solid ${themeMode === m ? theme.accent : theme.border}`,
              cursor: 'pointer', fontSize: 12, fontFamily: 'inherit' }}>{l}</button>
          ))}
        </div>
      </Row>
      <Sec label="同步" />
      <Row label="最後同步時間"><span style={{ fontSize: 13, color: theme.text.muted }}>剛才</span></Row>
      <Row label="">
        <button style={{ padding: '5px 14px', borderRadius: theme.radius.sm + 'px',
          border: `1px solid ${theme.border}`, background: 'none', cursor: 'pointer',
          fontSize: 13, color: theme.text.primary, fontFamily: 'inherit' }}>立即同步</button>
      </Row>
    </div>
  );
}

// ─── Sidebar ───────────────────────────────────────────────────

function Sidebar({ theme, currentScreen, onNavigate }) {
  const { projects, user } = window.DF_DATA;
  const NAV = [
    { id: 'today',    label: '今日',   icon: '○' },
    { id: 'calendar', label: '月曆',   icon: '□' },
    { id: 'pomodoro', label: '番茄鐘', icon: '◎' },
    { id: 'stats',    label: '統計',   icon: '≡' },
  ];
  function NavItem({ id, label, color, icon, sub }) {
    const active = currentScreen === id;
    const [h, sH] = useState(false);
    return (
      <button onClick={() => onNavigate(id)}
        onMouseEnter={() => sH(true)} onMouseLeave={() => sH(false)}
        style={{ display: 'flex', alignItems: 'center', gap: 8, width: '100%',
          padding: sub ? '5px 18px' : '6px 10px',
          paddingLeft: sub ? 18 : 10, borderRadius: 6,
          background: active ? theme.sidebar.activeBg : h ? theme.sidebar.activeBg + '55' : 'transparent',
          color: active ? theme.sidebar.activeText : theme.sidebar.text,
          border: 'none', borderLeft: active && !sub ? `2.5px solid ${theme.accent}` : '2.5px solid transparent',
          cursor: 'pointer', textAlign: 'left',
          fontSize: sub ? 13 : 14, fontWeight: active ? 600 : 400,
          fontFamily: 'inherit', transition: 'background .1s' }}>
        {color
          ? <span style={{ width: 7, height: 7, borderRadius: '50%', background: color, flexShrink: 0 }} />
          : <span style={{ fontSize: 10, opacity: .55 }}>{icon}</span>}
        {label}
      </button>
    );
  }
  return (
    <div style={{ width: 220, background: theme.sidebar.bg, flexShrink: 0,
      borderRight: `1px solid ${theme.sidebar.border || theme.border}`,
      display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
      {/* Logo */}
      <div style={{ padding: '18px 16px 14px', display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 26, height: 26, borderRadius: 6, background: theme.accent,
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <span style={{ color: 'white', fontSize: 13, fontWeight: 700 }}>S</span>
        </div>
        <span style={{ fontSize: 14, fontWeight: 700, color: theme.sidebar.activeText }}>SakunaFlow</span>
      </div>
      {/* Nav */}
      <div style={{ padding: '0 8px', flex: 1, display: 'flex', flexDirection: 'column', gap: 1, overflowY: 'auto' }}>
        {NAV.map(n => <NavItem key={n.id} {...n} />)}
        <div style={{ margin: '12px 4px 4px', fontSize: 10, fontWeight: 700, color: theme.sidebar.text,
          textTransform: 'uppercase', letterSpacing: '0.7px', padding: '0 8px' }}>專案</div>
        {projects.map(p => <NavItem key={p.id} id={`proj-${p.id}`} label={p.name} color={p.color} sub />)}
        <button style={{ display: 'flex', alignItems: 'center', gap: 6, padding: '5px 20px',
          borderRadius: 6, background: 'transparent', color: theme.sidebar.text, border: 'none',
          cursor: 'pointer', textAlign: 'left', fontSize: 13, fontFamily: 'inherit', opacity: .5 }}>
          ＋ 新增專案
        </button>
      </div>
      {/* Bottom */}
      <div style={{ padding: '8px', borderTop: `1px solid ${theme.sidebar.border || theme.border}` }}>
        <NavItem id="settings" label="設定" icon="⚙" />
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '8px 12px' }}>
          <div style={{ width: 26, height: 26, borderRadius: '50%', background: theme.accent,
            display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>
            <span style={{ color: 'white', fontSize: 11, fontWeight: 700 }}>陳</span>
          </div>
          <span style={{ fontSize: 13, color: theme.sidebar.text, overflow: 'hidden',
            textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{user.name}</span>
        </div>
      </div>
    </div>
  );
}

// ─── TopBar ────────────────────────────────────────────────────

function TopBar({ theme }) {
  return (
    <div style={{ height: 44, borderBottom: `1px solid ${theme.border}`, display: 'flex',
      alignItems: 'center', justifyContent: 'flex-end', padding: '0 24px', gap: 16, flexShrink: 0 }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 12, color: theme.text.muted }}>
        <span style={{ width: 6, height: 6, borderRadius: '50%', background: '#1aae39', display: 'inline-block' }} />
        已同步
      </div>
    </div>
  );
}

// ─── DesktopApp ────────────────────────────────────────────────

function DesktopApp({ theme, initialScreen = 'today', interactive = true }) {
  const [screen, setScreen] = useState(initialScreen);
  useEffect(() => { if (!interactive) setScreen(initialScreen); }, [initialScreen]);
  const nav = interactive ? setScreen : () => {};
  const MAP = { today: TodayScreen, pomodoro: PomodoroScreen, calendar: CalendarScreen,
                projects: ProjectsScreen, stats: StatsScreen, settings: SettingsScreen };
  const S = MAP[screen] || TodayScreen;
  return (
    <div style={{ width: 960, height: 726, display: 'flex', background: theme.bg,
      overflow: 'hidden', fontFamily: theme.font }}>
      <Sidebar theme={theme} currentScreen={screen} onNavigate={nav} />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}>
        <TopBar theme={theme} />
        <div style={{ flex: 1, overflowY: 'auto' }}><S theme={theme} interactive={interactive} /></div>
      </div>
    </div>
  );
}

// ─── iOS App ───────────────────────────────────────────────────

function IOSApp({ theme, initialScreen = 'today' }) {
  const [screen, setScreen] = useState(initialScreen);
  const TABS = [
    { id: 'today',    label: '今日',   icon: '○' },
    { id: 'calendar', label: '月曆',   icon: '□' },
    { id: 'pomodoro', label: '番茄鐘', icon: '◎' },
    { id: 'projects', label: '專案',   icon: '⊞' },
    { id: 'stats',    label: '更多',   icon: '⋯' },
  ];
  const MAP = { today: TodayScreen, pomodoro: PomodoroScreen, calendar: CalendarScreen,
                projects: ProjectsScreen, stats: StatsScreen };
  const S = MAP[screen] || TodayScreen;
  return (
    <div style={{ width: 390, height: 844, background: theme.bg, borderRadius: 48,
      boxShadow: '0 30px 100px rgba(0,0,0,0.55)', overflow: 'hidden',
      display: 'flex', flexDirection: 'column', border: '8px solid #1a1a1a', position: 'relative' }}>
      {/* Status bar */}
      <div style={{ height: 50, background: theme.bg, flexShrink: 0, display: 'flex',
        alignItems: 'center', justifyContent: 'center', position: 'relative' }}>
        <div style={{ width: 100, height: 28, background: '#111', borderRadius: 18, position: 'absolute', top: 10 }} />
        <span style={{ fontSize: 12, color: theme.text.muted, position: 'absolute', right: 20, top: 16 }}>9:41</span>
        <span style={{ fontSize: 12, color: theme.text.muted, position: 'absolute', left: 20, top: 16 }}>●●●●</span>
      </div>
      {/* Content */}
      <div style={{ flex: 1, overflowY: 'auto' }}>
        <S theme={theme} interactive={true} />
      </div>
      {/* Bottom tabs */}
      <div style={{ height: 82, background: theme.bg, borderTop: `1px solid ${theme.border}`,
        display: 'flex', alignItems: 'flex-start', paddingTop: 8, flexShrink: 0 }}>
        {TABS.map(t => (
          <button key={t.id} onClick={() => setScreen(t.id)}
            style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center',
              gap: 3, background: 'none', border: 'none', cursor: 'pointer', padding: '4px 0' }}>
            <span style={{ fontSize: 22, color: screen === t.id ? theme.accent : theme.text.muted }}>{t.icon}</span>
            <span style={{ fontSize: 10, fontFamily: theme.font, fontWeight: screen === t.id ? 600 : 400,
              color: screen === t.id ? theme.accent : theme.text.muted }}>{t.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
}

// ─── Export ────────────────────────────────────────────────────

Object.assign(window, {
  PriorityBadge, ProjectLabel, TaskCheckbox, TaskItem, SectionHeader, PrimaryBtn,
  TodayScreen, PomodoroScreen, CalendarScreen, ProjectsScreen, StatsScreen, SettingsScreen,
  Sidebar, TopBar, DesktopApp, IOSApp,
});
