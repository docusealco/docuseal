#!/usr/bin/env python3
"""
Script to parse epic details markdown and generate a presentation-style website
showing all user stories with User Story, Background, and Acceptance Criteria.
"""

import re
from pathlib import Path

def parse_epic_details(file_path):
    """Parse the epic details markdown file and extract stories."""

    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Split by stories
    story_pattern = r'### Story ([\d.]+): (.+?)\n\n(.*?)(?=\n### Story [\d.]+:|$)'
    matches = re.findall(story_pattern, content, re.DOTALL)

    stories = []
    for story_num, title, body in matches:
        # Extract User Story
        user_story_match = re.search(r'#### User Story\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
        user_story = user_story_match.group(1).strip() if user_story_match else "Not found"

        # Extract Background
        background_match = re.search(r'#### Background\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
        background = background_match.group(1).strip() if background_match else "Not found"

        # Extract Acceptance Criteria
        acceptance_match = re.search(r'#### Acceptance Criteria\n\n(.*?)(?=\n####|$)', body, re.DOTALL)
        acceptance = acceptance_match.group(1).strip() if acceptance_match else "Not found"

        # Clean up content
        user_story = clean_content(user_story)
        background = clean_content(background)
        acceptance = clean_content(acceptance)

        stories.append({
            'number': story_num,
            'title': title,
            'user_story': user_story,
            'background': background,
            'acceptance': acceptance
        })

    return stories

def clean_content(text):
    """Clean and escape content for HTML/JS embedding."""
    if not text:
        return ""
    # Replace problematic characters but preserve meaningful formatting
    text = text.replace('\\', '\\\\')
    text = text.replace("'", "\\'")
    text = text.replace('"', '\\"')
    text = text.replace('\n', '\\n')
    return text

def generate_html(stories):
    """Generate the HTML presentation website."""

    # Build the HTML structure
    html_parts = [
        '<!DOCTYPE html>',
        '<html lang="en">',
        '<head>',
        '    <meta charset="UTF-8">',
        '    <meta name="viewport" content="width=device-width, initial-scale=1.0">',
        '    <title>FloDoc User Stories - Epic Details</title>',
        '    <style>',
        '        * { margin: 0; padding: 0; box-sizing: border-box; }',
        '        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); height: 100vh; overflow: hidden; }',
        '        .slide-container { width: 100vw; height: 100vh; display: flex; justify-content: center; align-items: center; padding: 2rem; }',
        '        .slide { width: 90%; max-width: 1200px; height: 90%; background: white; border-radius: 20px; box-shadow: 0 20px 60px rgba(0,0,0,0.3); padding: 3rem; overflow-y: auto; display: none; animation: fadeIn 0.5s ease-in-out; }',
        '        .slide.active { display: block; }',
        '        @keyframes fadeIn { from { opacity: 0; transform: translateY(20px); } to { opacity: 1; transform: translateY(0); } }',
        '        .slide-header { border-bottom: 3px solid #667eea; padding-bottom: 1rem; margin-bottom: 2rem; }',
        '        .story-number { font-size: 1.2rem; color: #667eea; font-weight: 600; margin-bottom: 0.5rem; }',
        '        .story-title { font-size: 2rem; font-weight: 700; color: #1a202c; line-height: 1.3; }',
        '        .section { margin-bottom: 2rem; }',
        '        .section-title { font-size: 1.3rem; font-weight: 600; color: #667eea; margin-bottom: 1rem; display: flex; align-items: center; gap: 0.5rem; }',
        '        .section-title::before { content: ""; width: 4px; height: 24px; background: #667eea; border-radius: 2px; }',
        '        .section-content { background: #f7fafc; padding: 1.5rem; border-radius: 8px; line-height: 1.8; color: #2d3748; font-size: 1rem; }',
        '        .section-content strong { color: #667eea; }',
        '        .section-content ul, .section-content ol { margin-left: 1.5rem; margin-top: 0.5rem; }',
        '        .section-content li { margin-bottom: 0.5rem; }',
        '        .section-content code { background: #edf2f7; padding: 0.2rem 0.4rem; border-radius: 4px; font-family: "Courier New", monospace; font-size: 0.9rem; }',
        '        .navigation { position: fixed; bottom: 2rem; left: 50%; transform: translateX(-50%); background: rgba(255,255,255,0.95); padding: 1rem 2rem; border-radius: 50px; box-shadow: 0 4px 20px rgba(0,0,0,0.2); display: flex; gap: 1rem; align-items: center; z-index: 1000; }',
        '        .nav-btn { background: #667eea; color: white; border: none; padding: 0.75rem 1.5rem; border-radius: 25px; cursor: pointer; font-weight: 600; transition: all 0.3s ease; font-size: 1rem; }',
        '        .nav-btn:hover { background: #5568d3; transform: translateY(-2px); box-shadow: 0 4px 12px rgba(102,126,234,0.4); }',
        '        .nav-btn:disabled { background: #cbd5e0; cursor: not-allowed; transform: none; }',
        '        .nav-btn.secondary { background: #718096; }',
        '        .nav-btn.secondary:hover { background: #4a5568; }',
        '        .progress-bar { position: fixed; top: 0; left: 0; height: 4px; background: #667eea; transition: width 0.3s ease; z-index: 1001; }',
        '        .slide-counter { font-weight: 600; color: #4a5568; min-width: 100px; text-align: center; }',
        '        .slide::-webkit-scrollbar { width: 8px; }',
        '        .slide::-webkit-scrollbar-track { background: #f1f1f1; border-radius: 10px; }',
        '        .slide::-webkit-scrollbar-thumb { background: #667eea; border-radius: 10px; }',
        '        .slide::-webkit-scrollbar-thumb:hover { background: #5568d3; }',
        '        @media (max-width: 768px) { .slide { padding: 1.5rem; width: 95%; } .story-title { font-size: 1.5rem; } .section-title { font-size: 1.1rem; } .section-content { font-size: 0.9rem; padding: 1rem; } .navigation { padding: 0.75rem 1rem; gap: 0.5rem; } .nav-btn { padding: 0.5rem 1rem; font-size: 0.9rem; } }',
        '        .loading { text-align: center; padding: 2rem; color: white; font-size: 1.5rem; }',
        '    </style>',
        '</head>',
        '<body>',
        '    <div class="progress-bar" id="progressBar"></div>',
        '    <div id="slidesContainer"><div class="loading">Loading stories...</div></div>',
        '    <div class="navigation" id="navigation" style="display: none;">',
        '        <button class="nav-btn secondary" id="prevBtn" onclick="prevSlide()">← Previous</button>',
        '        <span class="slide-counter" id="slideCounter">1 / 32</span>',
        '        <button class="nav-btn" id="nextBtn" onclick="nextSlide()">Next →</button>',
        '    </div>',
        '    <script>',
        '        const stories = [];',
        '        let currentSlide = 0;',
        '        function initializeSlides() {',
        '            const container = document.getElementById("slidesContainer");',
        '            container.innerHTML = "";',
        '            stories.forEach((story, index) => {',
        '                const slide = document.createElement("div");',
        '                slide.className = "slide";',
        '                slide.id = `slide-${index}`;',
        '                slide.innerHTML = `',
        '                    <div class="slide-header">',
        '                        <div class="story-number">Story ${story.number}</div>',
        '                        <div class="story-title">${story.title}</div>',
        '                    </div>',
        '                    <div class="section">',
        '                        <div class="section-title">User Story</div>',
        '                        <div class="section-content">${formatContent(story.user_story)}</div>',
        '                    </div>',
        '                    <div class="section">',
        '                        <div class="section-title">Background</div>',
        '                        <div class="section-content">${formatContent(story.background)}</div>',
        '                    </div>',
        '                    <div class="section">',
        '                        <div class="section-title">Acceptance Criteria</div>',
        '                        <div class="section-content">${formatContent(story.acceptance)}</div>',
        '                    </div>',
        '                `;',
        '                container.appendChild(slide);',
        '            });',
        '            showSlide(0);',
        '            document.getElementById("navigation").style.display = "flex";',
        '        }',
        '        function formatContent(text) {',
        '            if (!text) return "";',
        '            let html = text;',
        '            html = html.replace(/\\*\\*(.+?)\\*\\*/g, "<strong>$1</strong>");',
        '            html = html.replace(/^[\\*\\-]\\s+(.+)$/gm, "<li>$1</li>");',
        '            html = html.replace(/(<li>.*<\\/li>)/s, "<ul>$1</ul>");',
        '            html = html.replace(/^\\d+\\.\\s+(.+)$/gm, "<li>$1</li>");',
        '            html = html.replace(/(<li>.*<\\/li>)/s, "<ul>$1</ul>");',
        '            html = html.replace(/\\n\\n/g, "</p><p>");',
        '            html = "<p>" + html + "</p>";',
        '            html = html.replace(/<p><ul>/g, "<ul>");',
        '            html = html.replace(/<\\/ul><\\/p>/g, "</ul>");',
        '            html = html.replace(/<p><\\/p>/g, "");',
        '            return html;',
        '        }',
        '        function showSlide(index) {',
        '            const slides = document.querySelectorAll(".slide");',
        '            slides.forEach((slide, i) => { slide.classList.toggle("active", i === index); });',
        '            currentSlide = index;',
        '            updateNavigation();',
        '            updateProgress();',
        '        }',
        '        function updateNavigation() {',
        '            const prevBtn = document.getElementById("prevBtn");',
        '            const nextBtn = document.getElementById("nextBtn");',
        '            const counter = document.getElementById("slideCounter");',
        '            prevBtn.disabled = currentSlide === 0;',
        '            nextBtn.disabled = currentSlide === stories.length - 1;',
        '            counter.textContent = `${currentSlide + 1} / ${stories.length}`;',
        '        }',
        '        function updateProgress() {',
        '            const progress = ((currentSlide + 1) / stories.length) * 100;',
        '            document.getElementById("progressBar").style.width = progress + "%";',
        '        }',
        '        function nextSlide() { if (currentSlide < stories.length - 1) showSlide(currentSlide + 1); }',
        '        function prevSlide() { if (currentSlide > 0) showSlide(currentSlide - 1); }',
        '        document.addEventListener("keydown", (e) => {',
        '            if (e.key === "ArrowRight" || e.key === " ") { e.preventDefault(); nextSlide(); }',
        '            else if (e.key === "ArrowLeft") { e.preventDefault(); prevSlide(); }',
        '        });',
    ]

    # Add stories data
    html_parts.append('        const storiesData = [')
    for story in stories:
        html_parts.append('            {')
        html_parts.append(f'                number: "{story["number"]}",')
        html_parts.append(f'                title: "{story["title"]}",')
        html_parts.append(f'                user_story: "{story["user_story"]}",')
        html_parts.append(f'                background: "{story["background"]}",')
        html_parts.append(f'                acceptance: "{story["acceptance"]}",')
        html_parts.append('            },')
    html_parts.append('        ];')

    # Add initialization
    html_parts.extend([
        '        if (document.readyState === "loading") {',
        '            document.addEventListener("DOMContentLoaded", () => {',
        '                stories.push(...storiesData);',
        '                initializeSlides();',
        '            });',
        '        } else {',
        '            stories.push(...storiesData);',
        '            initializeSlides();',
        '        }',
        '    </script>',
        '</body>',
        '</html>'
    ])

    return '\n'.join(html_parts)

def main():
    # Paths
    epic_file = Path('/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/prd/6-epic-details.md')
    output_dir = Path('/home/dev-mode/dev/dyict-projects/floDoc-v3/docs/backlog')
    output_html = output_dir / 'stories-presentation.html'

    print("Parsing epic details file...")
    stories = parse_epic_details(epic_file)

    print(f"Found {len(stories)} stories")
    print("Generating presentation HTML...")

    html = generate_html(stories)

    with open(output_html, 'w') as f:
        f.write(html)

    print(f"✅ Presentation generated: {output_html}")
    print(f"📊 Total stories: {len(stories)}")
    print("\nStories included:")
    for story in stories:
        print(f"  - {story['number']}: {story['title']}")

    # Also generate a summary markdown file
    summary_md = output_dir / 'STORIES_SUMMARY.md'
    with open(summary_md, 'w', encoding='utf-8') as f:
        f.write("# FloDoc User Stories - Summary\n\n")
        f.write(f"**Total Stories:** {len(stories)}\n\n")
        f.write("## Quick Reference\n\n")
        for story in stories:
            f.write(f"### {story['number']}: {story['title']}\n\n")
            f.write("**User Story:**\n")
            # Unescape for markdown
            user_story = story['user_story'].replace('\\n', '\n').replace('\\t', '\t')
            user_story = user_story.replace("\\'", "'").replace('\\"', '"')
            f.write(f"{user_story}\n\n")
            f.write("---\n\n")

    print(f"\n✅ Summary generated: {summary_md}")

if __name__ == '__main__':
    main()
