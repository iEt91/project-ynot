import type { ReactNode } from "react";

const metrics = [
  { label: "Users active", value: "1,248", trend: "+18%" },
  { label: "Activities today", value: "86", trend: "+7%" },
  { label: "Reports pending", value: "14", trend: "-3%" },
  { label: "Successful activity rate", value: "72.4%", trend: "+4.2%" },
];

const queue = [
  {
    title: "Coffee & Talk",
    zone: "Hongdae area",
    status: "ACTIVE",
    note: "3 confirmations, no flags",
  },
  {
    title: "Night Walk",
    zone: "Yeouido",
    status: "ONGOING",
    note: "1 open report under review",
  },
  {
    title: "Late Food Run",
    zone: "Myeongdong",
    status: "FULL",
    note: "Auto-archiving after wrap-up",
  },
];

const moderationQueue = [
  "Message flag: sensitive keyword detected in chat #24",
  "Activity review: location marked near private residence",
  "Report bundle: repeated no-show pattern from user_91",
];

export default function Home() {
  return (
    <main className="min-h-screen bg-[radial-gradient(circle_at_top,_rgba(255,119,183,0.18),_transparent_28%),linear-gradient(180deg,_#050816_0%,_#07111f_40%,_#050816_100%)] text-white">
      <div className="mx-auto flex min-h-screen w-full max-w-7xl flex-col px-6 py-8 lg:px-10">
        <header className="mb-8 flex flex-col gap-4 rounded-[32px] border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur md:flex-row md:items-end md:justify-between">
          <div>
            <p className="text-sm font-semibold uppercase tracking-[0.3em] text-pink-300/90">
              Project Ynot Admin
            </p>
            <h1 className="mt-3 text-3xl font-black tracking-tight md:text-5xl">
              Control room for micro-companionship
            </h1>
            <p className="mt-3 max-w-2xl text-sm leading-6 text-slate-300 md:text-base">
              Internal only. Monitor activities, review reports, manage users,
              and keep the city utility safe without turning it into a social
              network.
            </p>
          </div>
          <div className="flex flex-wrap gap-3">
            <Badge>Super admin mode</Badge>
            <Badge>Audit logging on</Badge>
            <Badge>RLS enforced</Badge>
          </div>
        </header>

        <section className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
          {metrics.map((metric) => (
            <MetricCard key={metric.label} {...metric} />
          ))}
        </section>

        <section className="mt-8 grid gap-6 xl:grid-cols-[1.4fr_0.9fr]">
          <Panel title="Activity control">
            <div className="grid gap-3">
              {queue.map((item) => (
                <QueueRow key={item.title} {...item} />
              ))}
            </div>
          </Panel>

          <Panel title="Moderation queue">
            <div className="grid gap-3">
              {moderationQueue.map((item) => (
                <div
                  key={item}
                  className="rounded-2xl border border-white/10 bg-slate-950/70 p-4 text-sm text-slate-200"
                >
                  {item}
                </div>
              ))}
            </div>
          </Panel>
        </section>

        <section className="mt-8 grid gap-6 lg:grid-cols-3">
          <Panel title="User actions">
            <ActionList
              items={[
                "Search by phone hash or nickname",
                "Set TRUSTED / LIMITED / SHADOWBANNED",
                "Review activity history and reports",
              ]}
            />
          </Panel>
          <Panel title="Live safety">
            <ActionList
              items={[
                "Open flagged chat context",
                "Translate Korean to English or Spanish",
                "Export evidence for legal review",
              ]}
            />
          </Panel>
          <Panel title="Roadmap">
            <ActionList
              items={[
                "Sprint 1: auth, map, activities",
                "Sprint 2: reports, chat, moderation",
                "Sprint 3: feedback and analytics",
              ]}
            />
          </Panel>
        </section>
      </div>
    </main>
  );
}

function Panel({
  title,
  children,
}: {
  title: string;
  children: ReactNode;
}) {
  return (
    <div className="rounded-[30px] border border-white/10 bg-white/5 p-6 shadow-2xl backdrop-blur">
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-black tracking-tight">{title}</h2>
        <span className="h-2 w-2 rounded-full bg-pink-300 shadow-[0_0_18px_rgba(255,119,183,0.8)]" />
      </div>
      {children}
    </div>
  );
}

function MetricCard({
  label,
  value,
  trend,
}: {
  label: string;
  value: string;
  trend: string;
}) {
  return (
    <div className="rounded-[28px] border border-white/10 bg-slate-950/70 p-5 shadow-xl">
      <p className="text-sm text-slate-400">{label}</p>
      <div className="mt-4 flex items-end justify-between gap-4">
        <div className="text-3xl font-black tracking-tight text-white">
          {value}
        </div>
        <div className="rounded-full bg-pink-500/15 px-3 py-1 text-xs font-bold text-pink-200">
          {trend}
        </div>
      </div>
    </div>
  );
}

function QueueRow({
  title,
  zone,
  status,
  note,
}: {
  title: string;
  zone: string;
  status: string;
  note: string;
}) {
  return (
    <div className="flex flex-col gap-3 rounded-[24px] border border-white/10 bg-slate-950/65 p-4 md:flex-row md:items-center md:justify-between">
      <div>
        <p className="font-bold text-white">{title}</p>
        <p className="mt-1 text-sm text-slate-400">
          {zone} · {note}
        </p>
      </div>
      <span className="inline-flex w-fit rounded-full bg-cyan-400/15 px-3 py-1 text-xs font-bold text-cyan-200">
        {status}
      </span>
    </div>
  );
}

function ActionList({ items }: { items: string[] }) {
  return (
    <ul className="space-y-3 text-sm leading-6 text-slate-300">
      {items.map((item) => (
        <li key={item} className="flex items-start gap-3">
          <span className="mt-2 h-2 w-2 rounded-full bg-pink-300" />
          <span>{item}</span>
        </li>
      ))}
    </ul>
  );
}

function Badge({ children }: { children: ReactNode }) {
  return (
    <span className="inline-flex items-center rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs font-semibold uppercase tracking-[0.2em] text-slate-200">
      {children}
    </span>
  );
}
