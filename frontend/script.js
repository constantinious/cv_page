// ===========================
// Visitor Counter API
// ===========================
const API_ENDPOINT = "https://fs2kyxrht4.execute-api.us-east-1.amazonaws.com/prod/visitor-count";

async function updateVisitorCount() {
    const counterElement = document.getElementById("visitor-count");
    try {
        const response = await fetch(API_ENDPOINT, {
            method: "POST",
            headers: {
                "Content-Type": "application/json",
            },
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const data = await response.json();
        counterElement.textContent = data.visitor_count.toLocaleString();
    } catch (error) {
        console.error("Failed to fetch visitor count:", error);
        counterElement.textContent = "—";
    }
}

// ===========================
// Mobile Navigation Toggle
// ===========================
function initNavigation() {
    const navToggle = document.querySelector(".nav-toggle");
    const navLinks = document.querySelector(".nav-links");

    if (navToggle && navLinks) {
        navToggle.addEventListener("click", () => {
            navLinks.classList.toggle("active");
            const icon = navToggle.querySelector("i");
            icon.classList.toggle("fa-bars");
            icon.classList.toggle("fa-times");
        });

        // Close mobile menu when a link is clicked
        navLinks.querySelectorAll("a").forEach((link) => {
            link.addEventListener("click", () => {
                navLinks.classList.remove("active");
                const icon = navToggle.querySelector("i");
                icon.classList.add("fa-bars");
                icon.classList.remove("fa-times");
            });
        });
    }
}

// ===========================
// Scroll Animations
// ===========================
function initScrollAnimations() {
    const elements = document.querySelectorAll(
        ".timeline-item, .skill-card, .cert-card, .edu-card, .project-card, .contact-item"
    );

    elements.forEach((el) => el.classList.add("fade-in"));

    const observer = new IntersectionObserver(
        (entries) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target.classList.add("visible");
                }
            });
        },
        { threshold: 0.1, rootMargin: "0px 0px -50px 0px" }
    );

    elements.forEach((el) => observer.observe(el));
}

// ===========================
// Navbar Background on Scroll
// ===========================
function initNavbarScroll() {
    const navbar = document.querySelector(".navbar");
    window.addEventListener("scroll", () => {
        if (window.scrollY > 50) {
            navbar.style.borderBottomColor = "rgba(51, 65, 85, 0.8)";
            navbar.style.boxShadow = "0 4px 20px rgba(0, 0, 0, 0.3)";
        } else {
            navbar.style.borderBottomColor = "var(--color-border)";
            navbar.style.boxShadow = "none";
        }
    });
}

// ===========================
// Initialize
// ===========================
document.addEventListener("DOMContentLoaded", () => {
    initNavigation();
    initScrollAnimations();
    initNavbarScroll();
    updateVisitorCount();
});
