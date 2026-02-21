#!/bin/bash
# Audit existing projects and suggest plugin configurations
# Usage: audit-projects.sh [directory]

set -e

SEARCH_DIR="${1:-.}"
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${BLUE}=== Claude Plugin Configuration Audit ===${NC}\n"

# Find all git repositories
echo -e "${CYAN}Scanning for git repositories in: $SEARCH_DIR${NC}\n"

detect_project_type() {
    local dir=$1
    local suggestions=()
    local reasoning=""

    # Check for specific files/patterns
    if [ -f "$dir/package.json" ]; then
        if grep -q "stripe" "$dir/package.json" 2>/dev/null; then
            suggestions+=("3")  # Web Dev + Stripe
            reasoning="package.json contains Stripe dependency"
        elif grep -q "\"react\"\|\"vue\"\|\"angular\"\|\"next\"" "$dir/package.json" 2>/dev/null; then
            suggestions+=("1")  # Software Dev
            reasoning="Node.js/JavaScript project detected"
        fi
    fi

    if [ -f "$dir/requirements.txt" ] || [ -f "$dir/setup.py" ] || [ -f "$dir/pyproject.toml" ]; then
        if grep -q "pandas\|numpy\|airflow\|prefect\|dbt" "$dir/requirements.txt" "$dir/setup.py" "$dir/pyproject.toml" 2>/dev/null; then
            suggestions+=("2")  # Data Engineering
            reasoning="Python data engineering tools detected"
        else
            suggestions+=("1")  # Software Dev
            reasoning="Python project detected"
        fi
    fi

    if [ -f "$dir/Dockerfile" ] || [ -f "$dir/docker-compose.yml" ]; then
        suggestions+=("1")  # Software Dev
        reasoning="Docker configuration found"
    fi

    if compgen -G "$dir/.github/workflows/"'*.yml' > /dev/null 2>&1; then
        suggestions+=("1")  # Software Dev
        reasoning="GitHub Actions workflows present"
    fi

    # Check README for keywords
    if [ -f "$dir/README.md" ]; then
        if grep -qi "etl\|pipeline\|data.*engineer\|airflow\|spark" "$dir/README.md" 2>/dev/null; then
            suggestions+=("2")  # Data Engineering
            reasoning="ETL/Data pipeline project (from README)"
        elif grep -qi "stripe\|payment\|checkout" "$dir/README.md" 2>/dev/null; then
            suggestions+=("3")  # Web Dev + Stripe
            reasoning="Payment integration project (from README)"
        elif grep -qi "notion\|linear\|jira\|project.*management" "$dir/README.md" 2>/dev/null; then
            suggestions+=("4")  # Business/PM
            reasoning="Project management tools mentioned"
        fi
    fi

    # Default to Software Dev if nothing specific detected
    if [ ${#suggestions[@]} -eq 0 ]; then
        suggestions+=("1")
        reasoning="Default software development configuration"
    fi

    # Return first suggestion
    echo "${suggestions[0]}|$reasoning"
}

get_template_name() {
    case $1 in
        1) echo "Software Development" ;;
        2) echo "Data Engineering/ETL" ;;
        3) echo "Web Dev + Stripe" ;;
        4) echo "Business/PM" ;;
        5) echo "Communication" ;;
        6) echo "AV Production" ;;
        7) echo "Minimal" ;;
        *) echo "Unknown" ;;
    esac
}

count=0
declare -a projects
declare -a suggestions
declare -a reasons

while IFS= read -r -d '' git_dir; do
    project_dir=$(dirname "$git_dir")

    # Skip if already has .claude/settings.local.json
    if [ -f "$project_dir/.claude/settings.local.json" ]; then
        continue
    fi

    # Get project name
    project_name=$(basename "$project_dir")

    # Detect project type
    result=$(detect_project_type "$project_dir")
    template=$(echo "$result" | cut -d'|' -f1)
    reason=$(echo "$result" | cut -d'|' -f2)

    projects+=("$project_dir")
    suggestions+=("$template")
    reasons+=("$reason")

    ((count++))
done < <(find "$SEARCH_DIR" -type d -name ".git" -print0 2>/dev/null)

if [ $count -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All git repositories already have Claude configuration!"
    echo -e "\nTo modify existing configs, edit .claude/settings.local.json in each project."
    exit 0
fi

echo -e "${YELLOW}Found $count projects without Claude configuration:${NC}\n"

# Display findings
for i in "${!projects[@]}"; do
    project_name=$(basename "${projects[$i]}")
    template_name=$(get_template_name "${suggestions[$i]}")

    echo -e "${GREEN}$((i+1)).${NC} ${CYAN}$project_name${NC}"
    echo -e "   Path: ${projects[$i]}"
    echo -e "   Suggested: ${BLUE}$template_name${NC} (Template ${suggestions[$i]})"
    echo -e "   Reason: ${reasons[$i]}"
    echo ""
done

echo -e "${YELLOW}Options:${NC}"
echo "  1) Apply suggestions to all projects"
echo "  2) Apply suggestions interactively (review each)"
echo "  3) Export list for manual review"
echo "  4) Cancel"
echo ""
read -p "Enter your choice [1-4]: " choice

case $choice in
    1)
        echo -e "\n${BLUE}Applying configurations...${NC}\n"
        for i in "${!projects[@]}"; do
            project_name=$(basename "${projects[$i]}")
            echo -e "Configuring: ${CYAN}$project_name${NC}"
            cd "${projects[$i]}"
            ~/.claude/scripts/setup-project-plugins.sh "${suggestions[$i]}" 2>/dev/null
        done
        echo -e "\n${GREEN}✓ All projects configured!${NC}"
        ;;
    2)
        echo -e "\n${BLUE}Interactive configuration...${NC}\n"
        for i in "${!projects[@]}"; do
            project_name=$(basename "${projects[$i]}")
            template_name=$(get_template_name "${suggestions[$i]}")

            echo -e "${CYAN}$project_name${NC}"
            echo -e "Suggested: ${BLUE}$template_name${NC}"
            echo -e "Reason: ${reasons[$i]}"
            echo ""
            read -p "Apply this configuration? [Y/n/c=custom/s=skip]: " answer

            case $answer in
                [Cc])
                    cd "${projects[$i]}"
                    ~/.claude/scripts/setup-project-plugins.sh 8
                    ;;
                [Ss])
                    echo "Skipped"
                    ;;
                [Nn])
                    echo "Choose template:"
                    echo "  1) Software Dev  2) Data Engineering  3) Web+Stripe"
                    echo "  4) Business/PM   5) Communication     6) AV Production"
                    echo "  7) Minimal       8) Custom"
                    read -p "Template: " template
                    cd "${projects[$i]}"
                    ~/.claude/scripts/setup-project-plugins.sh "$template"
                    ;;
                *)
                    cd "${projects[$i]}"
                    ~/.claude/scripts/setup-project-plugins.sh "${suggestions[$i]}" 2>/dev/null
                    echo -e "${GREEN}✓ Configured${NC}"
                    ;;
            esac
            echo ""
        done
        echo -e "${GREEN}✓ Interactive configuration complete!${NC}"
        ;;
    3)
        output_file="/tmp/claude-project-audit-$(date +%Y%m%d-%H%M%S).txt"
        echo "Claude Plugin Configuration Audit" > "$output_file"
        echo "Generated: $(date)" >> "$output_file"
        echo "" >> "$output_file"

        for i in "${!projects[@]}"; do
            project_name=$(basename "${projects[$i]}")
            template_name=$(get_template_name "${suggestions[$i]}")

            echo "$((i+1)). $project_name" >> "$output_file"
            echo "   Path: ${projects[$i]}" >> "$output_file"
            echo "   Suggested: $template_name (Template ${suggestions[$i]})" >> "$output_file"
            echo "   Reason: ${reasons[$i]}" >> "$output_file"
            echo "" >> "$output_file"
        done

        echo -e "${GREEN}✓${NC} Exported to: $output_file"
        cat "$output_file"
        ;;
    *)
        echo "Cancelled"
        exit 0
        ;;
esac
