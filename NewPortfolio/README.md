# Shanmukha — DevOps Resume Site

## Structure
resume-site/
├── index.html          # All page content (hero, about, experience, certs, projects, contact)
├── css/
│   └── style.css        # All styling (theme colors, layout, fonts)
├── assets/
│   ├── Shanmukha_DevOps_Resume.pdf   # One-page downloadable resume (linked in nav + hero)
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

## Updating the resume PDF
The PDF at assets/Shanmukha_DevOps_Resume.pdf is a placeholder-filled draft matching the
site content. To replace it: generate/export your real one-pager with the same filename
and drop it into assets/ — the download buttons in the nav bar and hero don't need any
code changes as long as the filename stays the same.

## Run locally
Just open index.html in a browser — no build step needed.

## Updating this line of code just for the sake of pipeline runs
