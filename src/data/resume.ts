/**
 * Résumé and homepage content. Edit here — the home and résumé pages both read
 * from these arrays, so a change shows up in both places.
 *
 * Blog posts are NOT here; they are markdown files in src/content/blog/.
 */

export interface SkillGroup {
  name: string;
  /** Tag colour: tag-accent | tag-accent-2 | tag-neutral */
  tagClass: string;
  items: string[];
}

export interface Stat {
  value: string;
  label: string;
  bg: string;
  color: string;
}

export interface HomeRole {
  company: string;
  title: string;
  blurb: string;
}

export interface Role {
  title: string;
  dates: string;
  bullets: string[];
}

export interface Company {
  company: string;
  location: string;
  roles: Role[];
}

export const SKILLS: SkillGroup[] = [
  {
    name: 'AI-Assisted Engineering',
    tagClass: 'tag-accent',
    items: [
      'Claude Code',
      'Agentic multi-agent workflows',
      'MCP integrations',
      'OpenSpec spec-driven dev',
      'AI-generated PRs',
      'Automated PR review',
      'AI-assisted test generation',
      'Context & prompt engineering',
    ],
  },
  {
    name: 'Languages & Frameworks',
    tagClass: 'tag-neutral',
    items: ['TypeScript', 'JavaScript', 'Node.js', 'React', 'React Native', 'Express', 'PHP', 'Java', 'SQL'],
  },
  {
    name: 'Cloud & Infrastructure',
    tagClass: 'tag-accent-2',
    items: [
      'AWS Lambda',
      'API Gateway',
      'DynamoDB',
      'S3',
      'ECS',
      'SQS / SNS',
      'Kinesis',
      'EventBridge',
      'Route 53',
      'Google Cloud',
      'Terraform',
      'Apigee',
      'Kong Gateway',
      'GitHub Actions',
      'Docker',
    ],
  },
  {
    name: 'Data & Messaging',
    tagClass: 'tag-neutral',
    items: ['PostgreSQL', 'PostGIS', 'MySQL', 'DynamoDB', 'MongoDB', 'Redis', 'RabbitMQ', 'NSQ'],
  },
  {
    name: 'Leadership',
    tagClass: 'tag-accent',
    items: [
      'Multi-team leadership',
      'Platform & API strategy',
      'Architecture review',
      'Technical roadmapping',
      'Hiring & interviewing',
      'Mentorship',
    ],
  },
];

export const STATS: Stat[] = [
  { value: '15+', label: 'Years in software engineering', bg: 'var(--color-accent-100)', color: 'var(--color-accent-700)' },
  { value: '50M', label: 'API requests secured per day', bg: 'var(--color-accent-2-200)', color: 'var(--color-accent-2-800)' },
  { value: '5x', label: 'P95 latency improvement delivered', bg: 'var(--color-accent-200)', color: 'var(--color-accent-700)' },
  { value: '20', label: 'Engineers led on a single team', bg: 'var(--color-accent-2-100)', color: 'var(--color-accent-2-800)' },
];

export const HOME_ROLES: HomeRole[] = [
  {
    company: 'Journey',
    title: 'Head of Product Engineering',
    blurb:
      'Built the agentic Claude Code workflow — spec-driven, MCP-integrated — that carries ideas to shipped, tested code far beyond traditional team throughput.',
  },
  {
    company: 'Ally Financial',
    title: 'Fellow Software Engineer',
    blurb:
      "Led the API Platform organization behind Ally's OAuth authentication tier, serving 50M+ requests a day, and the enterprise gateway migration to Kong.",
  },
  {
    company: 'Passport',
    title: 'Solutions Architect → Director',
    blurb:
      "Rose from senior engineer to Director of Engineering, shipping Passport's first public APIs and the shared services platform behind every product.",
  },
];

export const PROFILE =
  'Fellow-level software engineer and engineering leader with 15+ years of experience architecting, delivering, and operating cloud-native APIs, distributed systems, and full-stack SaaS platforms across high-growth startups and Fortune 100 enterprises. Most recently focused on AI-native software delivery — designing agentic development workflows built on Claude Code, spec-driven development with OpenSpec, and MCP integrations across Linear, Notion, Slack, GitHub, and Google Cloud that carry work from ambiguous product idea to reviewed, tested, shipped code. A trusted partner to product, DevOps, and platform peers, equally effective leading engineering and delivery organizations as contributing hands-on at the keyboard.';

export const EXPERIENCE: Company[] = [
  {
    company: 'Journey',
    location: 'Charlotte, NC (Remote)',
    roles: [
      {
        title: 'Head of Product Engineering',
        dates: 'April 2026 – July 2026',
        bullets: [
          'Designed, implemented, and continuously refined an AI agent–based development workflow built on Claude Code, using dynamic, multi-stage workflows to progress work from ambiguous product ideas to merged, tested, production ready code at a pace far beyond traditional team throughput.',
          'Introduced OpenSpec spec-driven development so that every change began with an explicit, reviewable specification — giving agents unambiguous intent, acceptance criteria, and scope boundaries, and giving human reviewers a single artifact of truth. Materially reduced rework, scope drift, and miscommunicated deliverables among projects requiring multiple engineers.',
          'Built and operated MCP integrations that gave agents first-class access to the tools the team already lived in: Linear for task management, Notion for documentation, Slack for communication and approvals, GitHub for source control and review, and Google Cloud for production triage and metrics.',
          'Automated the full pull request lifecycle with AI: agents generated implementation and test suites, opened PRs with contextual descriptions linked to their Linear issues and specs, performed automated code review against project standards, and applied fixes to review comments autonomously before requesting human sign-off.',
          'Used MCP-based Google Cloud integrations to give agents direct access to logs, traces, and metrics, enabling rapid incident triage and root-cause analysis with minimal manual context gathering.',
          'Established the guardrails that made agentic development safe and repeatable — specification review gates, automated test coverage requirements, human approval checkpoints, and consistent repository conventions that agents could reliably follow.',
          'Delivered multiple user-facing and back-office full-stack applications: React Native web and mobile UIs, TypeScript APIs and webhooks, integrations with dozens of hotel PMS systems, and a multi-stage, event-driven reservation lifecycle.',
          'Owned the Google Cloud Platform infrastructure supporting these applications end to end, implemented and maintained through infrastructure as code.',
        ],
      },
    ],
  },
  {
    company: 'Ally Financial',
    location: 'Charlotte, NC (Remote)',
    roles: [
      {
        title: 'Fellow Software Engineer',
        dates: 'September 2021 – March 2026',
        bullets: [
          "Led 10+ software, DevOps, and infrastructure engineers across several teams in Ally's API Platform organization, responsible for shared tooling and platforms powering API infrastructure enterprise-wide.",
          'Architected and implemented the proprietary OAuth provider servers responsible for issuing, minting, and validating the JWT tokens used by every Ally customer-facing and server-to-server API — serving over 50 million requests per day at peaks of 60,000 concurrent requests — reducing p95 latency 5x over the previous implementation.',
          'Designed, architected, and oversaw delivery of a proprietary framework and CLI for generating configuration-driven infrastructure as code and application code for serverless APIs — conceptually similar to AWS CDK — producing application scaffolding, Terraform, Apigee gateway configuration, and a local development environment.',
          'Delivered shared Node.js modules for logging, HTTP clients, multi-region Terraform infrastructure, and SDK generation, plus shared GitLab CI templates that centralized enterprise security, testing, and deployment functionality across all Ally digital APIs.',
          'Maintained the Enterprise API Gateway on Apigee — the entry point for all Ally APIs — implementing centralized security, quality, observability, and AuthN/AuthZ policies.',
          'Architected, implemented, and oversaw delivery of the migration from Apigee to Kong Gateway, modernizing the Ally API stack and hardening the security posture of API deployment and operation.',
          "Prototyped new vendors and cloud infrastructure patterns, leading to adoption of a modern headless CMS and to Ally's first production multi-region API application, built on Route 53, API Gateway, Lambda, DynamoDB, and S3.",
          "Drove hiring and talent development for the platform organization, partnering with staffing partners and Ally's internal technology academy to interview, onboard, and mentor engineers, including early-career hires.",
        ],
      },
    ],
  },
  {
    company: 'Passport',
    location: 'Charlotte, NC (Remote)',
    roles: [
      {
        title: 'Solutions Architect',
        dates: 'April 2021 – September 2021',
        bullets: [
          'Developed, documented, and disseminated organization-wide best practices and architectural patterns for all new and existing backend applications, using the full AWS toolset with a focus on resiliency, availability, performance, and scalability.',
          "Proactively designed, diagrammed, and documented solutions for new feature requests across Passport's parking and micro-mobility product suite, producing maintainable, flexible architectures.",
          'Implemented shared services, systems, and libraries that reduced friction for engineers on hard problems — application cache and configuration management, resiliency patterns, and remedies for common serverless performance pitfalls.',
        ],
      },
      {
        title: 'Staff Software Engineer',
        dates: 'February 2020 – April 2021',
        bullets: [
          "Implemented new functionality and maintained legacy systems across Passport's enforcement portfolio, including the front-end web interface and supporting API services for a client tooling and reporting portal used by hundreds of municipalities, built with Node.js, React, and AWS Lambda, API Gateway, SQS, SNS, DynamoDB, ECS, and MySQL.",
          'Provided technical expertise to portfolio leadership by prototyping new systems, designing and diagramming architectures, and advising on direction and feasibility.',
          'Mentored engineers on technical, interpersonal, and career growth through code review, pair programming, and training — including a Lunch & Learn program that I initiated, organized, and ran.',
        ],
      },
      {
        title: 'Director of Engineering',
        dates: 'May 2019 – January 2020',
        bullets: [
          "Led multiple engineering teams as director of Passport's shared services portfolio, designing and implementing reusable libraries and microservices for user management, authorization, geospatial data handling and analysis, and PCI payments.",
          "Designed, implemented, and released Passport's first public-facing APIs, enabling third-party developers to create and manage parking sessions — consumed by a mobile navigation application used by millions and by in-dash command centers from several major American automakers.",
          'Contributed to talent and capacity planning, hiring, and continuing education, and drove company-wide initiatives to revamp technical architecture and raise engineering maturity.',
          'Partnered with product and analyst teams on short- and long-term roadmaps, consulting on technical requirements, sizing, and dependency risk.',
        ],
      },
      {
        title: 'Senior Software Engineer / Technical Lead',
        dates: 'June 2018 – April 2019',
        bullets: [
          'Managed a team of up to 7 engineers on new transportation-industry products, including the backend logic for an industry-first mobile cashless tolling application that analyzed GPS data to determine entry and exit points and automatically charge tolling sessions, built on Node.js with AWS Lambda, API Gateway, Kinesis, and DynamoDB.',
          "Took over the delivery of a rewrite of Passport's mobile-pay parking backend that was struggling to scale, hit deadlines, and meet performance and availability SLOs, and drove it to completion.",
        ],
      },
    ],
  },
  {
    company: 'Bank of America',
    location: 'Charlotte, NC',
    roles: [
      {
        title: 'Vice President – Lead Application Consultant',
        dates: 'June 2016 – April 2018',
        bullets: [
          'Managed a team of 20 engineers responsible for all development functions of a target-state suite of developer support tools used enterprise-wide to build high-traffic customer-facing sites and internal applications, including the Bank of America homepage.',
          'Delivered CLI tooling for assembling proprietary JavaScript, CSS, and HTML modules into functioning applications, a web portal and supporting microservices providing CI capabilities, and content authoring and delivery services — built with Node.js, React, Redis, and MySQL.',
          'Provided leadership across every stage of the agile SDLC: feature development, requirements discovery, architecture definition, resource allocation, planning, and acceptance.',
          'Worked closely with enterprise DevOps, security, middleware, monitoring, and infrastructure teams to promote sustainable, industry-standard practices for running Node.js applications across the bank.',
          'Promoted a culture centered on code quality, rapid and consistent delivery, and continuous improvement through interviewing, hiring, training, and direct, honest feedback.',
        ],
      },
    ],
  },
  {
    company: 'Red Ventures',
    location: 'Charlotte, NC',
    roles: [
      {
        title: 'Director of Software Engineering',
        dates: 'February 2016 – June 2016',
        bullets: [
          'Managed a team of 7 engineers building and maintaining CRM, front-end marketing assets, product management systems, and order placement integrations with major partners including Verizon and American Express.',
          'Assisted in resource allocation, technical governance, and architectural decisions affecting all business partnerships and internal products.',
          'Spearheaded a continuous-learning initiative for a 100+ engineer organization covering React, Flux, Redux, CommonJS, Webpack, and Mocha, and helped launch a program for engineers to drive creative side projects.',
        ],
      },
      {
        title: 'Senior Software Engineer',
        dates: 'January 2014 – February 2016',
        bullets: [
          'Designed, architected, and implemented a modular, socket-based real-time sales platform providing CRM, phone system integration, agent workflow management, and order placement for hundreds of sales agents, built on Node.js, React with Flux, RabbitMQ, and Redis.',
          'Built and maintained every component of a real-time chat platform — customer-facing chat client, multi-chat agent interface, socket event handling and routing servers, RESTful CRM integration services, and backend message queuing.',
          "Integrated Facebook Messenger via Facebook's alpha live chat Node.js client into the existing chat platform through Redis and NSQ, and built a new agent UI with websockets, React, Redux, and Immutable.js.",
          'Developed an API framework for RESTful services with a data access layer supporting flexible partner-level functionality overrides, using Express, Node.js, PHP, Silex, and MySQL.',
        ],
      },
      {
        title: 'Lead Software Engineer',
        dates: 'February 2011 – December 2013',
        bullets: [
          'Managed a team of developers building and maintaining sales platforms, tooling, API integrations, and analytics visualization supporting partner relationships that generated over $30 million in revenue.',
          'Pitched, planned, and implemented long-term initiatives with business leadership, including a major legacy refactor and a disaster recovery system for partner outages.',
          'Launched full technology stacks for national brand partner integrations spanning SOAP API integration, agent order platforms, transactional schema design, and financial reconciliation, using PHP, MySQL, and JavaScript.',
        ],
      },
      {
        title: 'Junior Web Developer',
        dates: 'December 2009 – January 2011',
        bullets: [
          'Built dynamic data analysis tools and real-time dashboards for sales agents and business analysts, an administrative tool suite, and a split-testing framework for scripting and sales platform management, primarily in PHP, MySQL, and JavaScript.',
        ],
      },
    ],
  },
];
