// Theme Toggle
const themeToggle = document.getElementById('theme-toggle');
const body = document.body;

// Check for saved theme preference or default to dark mode
const currentTheme = localStorage.getItem('theme') || 'dark';
if (currentTheme === 'light') {
    body.classList.add('light-mode');
}

themeToggle.addEventListener('click', () => {
    body.classList.toggle('light-mode');
    const theme = body.classList.contains('light-mode') ? 'light' : 'dark';
    localStorage.setItem('theme', theme);
});

// Reading Progress Bar
const progressBar = document.querySelector('.progress-bar');

window.addEventListener('scroll', () => {
    const windowHeight = window.innerHeight;
    const documentHeight = document.documentElement.scrollHeight - windowHeight;
    const scrolled = window.scrollY;
    const progress = (scrolled / documentHeight) * 100;
    progressBar.style.width = progress + '%';
});

// Table of Contents Active Section Highlighting
const sections = document.querySelectorAll('section');
const tocLinks = document.querySelectorAll('.toc a');

window.addEventListener('scroll', () => {
    let current = '';
    
    sections.forEach(section => {
        const sectionTop = section.offsetTop;
        const sectionHeight = section.clientHeight;
        if (scrollY >= (sectionTop - 200)) {
            current = section.getAttribute('id');
        }
    });
    
    tocLinks.forEach(link => {
        link.classList.remove('active');
        if (link.getAttribute('href') === `#${current}`) {
            link.classList.add('active');
        }
    });
});

// Smooth scrolling for TOC links
tocLinks.forEach(link => {
    link.addEventListener('click', (e) => {
        e.preventDefault();
        const targetId = link.getAttribute('href').substring(1);
        const targetSection = document.getElementById(targetId);
        targetSection.scrollIntoView({ behavior: 'smooth' });
    });
});

// Intersection Observer for fade-in animations
const observerOptions = {
    threshold: 0.1,
    rootMargin: '0px 0px -50px 0px'
};

const observer = new IntersectionObserver((entries) => {
    entries.forEach(entry => {
        if (entry.isIntersecting) {
            entry.target.classList.add('visible');
        }
    });
}, observerOptions);

// Delay observer to prevent initial scroll jump
setTimeout(() => {
    document.querySelectorAll('.fade-in-section').forEach(section => {
        observer.observe(section);
    });
}, 100);

// Prevent scroll on page load
if (window.location.hash === '') {
    window.scrollTo(0, 0);
}

// Expandable References
document.querySelectorAll('.ref-expand').forEach(button => {
    button.addEventListener('click', () => {
        const details = button.nextElementSibling;
        const isExpanded = button.classList.contains('expanded');
        
        if (isExpanded) {
            button.classList.remove('expanded');
            details.classList.remove('show');
        } else {
            button.classList.add('expanded');
            details.classList.add('show');
        }
    });
});

// A/B Audio Comparison Tool
const abButtons = document.querySelectorAll('.ab-button');
const playPauseBtn = document.querySelector('.ab-play-pause');
const audioA = document.getElementById('audio-a');
const audioB = document.getElementById('audio-b');

let currentAudio = audioB;
let isPlaying = false;

// Synchronise audio times
audioA.addEventListener('timeupdate', () => {
    if (Math.abs(audioA.currentTime - audioB.currentTime) > 0.1) {
        audioB.currentTime = audioA.currentTime;
    }
});

audioB.addEventListener('timeupdate', () => {
    if (Math.abs(audioB.currentTime - audioA.currentTime) > 0.1) {
        audioA.currentTime = audioB.currentTime;
    }
});

// A/B switching
abButtons.forEach(button => {
    button.addEventListener('click', () => {
        const mode = button.dataset.mode;
        
        // Update active state
        abButtons.forEach(btn => btn.classList.remove('active'));
        button.classList.add('active');
        
        // Switch audio
        if (mode === 'a') {
            audioA.volume = 1;
            audioB.volume = 0;
            currentAudio = audioA;
        } else {
            audioA.volume = 0;
            audioB.volume = 1;
            currentAudio = audioB;
        }
    });
});

// Play/Pause functionality
playPauseBtn.addEventListener('click', () => {
    if (isPlaying) {
        audioA.pause();
        audioB.pause();
        playPauseBtn.textContent = '▶️ Play';
        isPlaying = false;
    } else {
        audioA.play();
        audioB.play();
        playPauseBtn.textContent = '⏸️ Pause';
        isPlaying = true;
    }
});

// Initialise with B (wet) active
audioA.volume = 0;
audioB.volume = 1;

// Handle audio ended
audioA.addEventListener('ended', () => {
    audioB.pause();
    playPauseBtn.textContent = '▶️ Play';
    isPlaying = false;
    audioA.currentTime = 0;
    audioB.currentTime = 0;
});

audioB.addEventListener('ended', () => {
    audioA.pause();
    playPauseBtn.textContent = '▶️ Play';
    isPlaying = false;
    audioA.currentTime = 0;
    audioB.currentTime = 0;
});

// Add custom syntax highlighting class for Faust (if Prism doesn't have it)
if (typeof Prism !== 'undefined') {
    Prism.languages.faust = Prism.languages.extend('clike', {
        'keyword': /\b(?:process|import|declare|with|letrec|environment|component|library|effect|instrument)\b/,
        'builtin': /\b(?:hslider|vslider|button|checkbox|nentry|hgroup|vgroup|tgroup)\b/,
        'function': /\b(?:sin|cos|tan|exp|log|sqrt|abs|min|max|select2|par|seq|sum|prod)\b/,
        'operator': /[~:,<>]/,
        'number': /\b\d+(?:\.\d+)?(?:[eE][+-]?\d+)?\b/
    });
}