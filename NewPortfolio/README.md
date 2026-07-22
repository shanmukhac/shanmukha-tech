# Shanmukha — DevOps Resume Site

## Structure
resume-site/
├── index.html          # All page content (hero, about, experience, certs, projects, contact)
├── css/
│   └── style.css        # All styling (theme colors, layout, fonts)
├── assets/
│   ├── certs/            # Put real certification badge/logo images here
│   └── icons/            # Optional: favicon or extra icons here
└── README.md

## Where to edit
- Contact info: index.html, inside <section class="hero">
- About text: index.html, id="about"
- Experience: index.html, id="experience"
- Certifications: index.html, id="certifications"
- Projects (GitHub links): index.html, id="projects" — update each <a class="project-card" href="...">
- Socials: index.html, id="contact"
- Colors/fonts: css/style.css, the :root variables at the top

## Run locally
Just open index.html in a browser — no build step needed.
