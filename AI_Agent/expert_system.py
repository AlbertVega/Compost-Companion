import sys
import os

# Add parent directory to sys.path to allow importing from schemas
current_dir = os.path.dirname(os.path.abspath(__file__))
parent_dir = os.path.dirname(current_dir)
if parent_dir not in sys.path:
    sys.path.append(parent_dir)

from schemas import RecipeIngredient, ExpertSuggestion, RecipeEvaluation
from typing import List, Optional

class CompostExpertSystem:
    """
    Rule-Based Expert System that evaluates a compost mix recipe.
    It calculates the overall moisture and Carbon-to-Nitrogen (C/N) ratio,
    and returns recommendations to help the user achieve optimal composting conditions.
    """
    def __init__(self):
        # optimal ranges (literature ideal)
        self.min_cn_ratio = 25.0
        self.max_cn_ratio = 30.0
        self.min_moisture = 40.0
        self.max_moisture = 50.0

    def calculate_required_weight_for_cn(self, target_cn: float, current_carbon_kg: float, current_nitrogen_kg: float, ingredient: RecipeIngredient) -> float:
        """
        Calculate the required wet weight of an ingredient to achieve a target C/N ratio.
        """
        m_new = ingredient.moisture_content / 100.0
        c_new = ingredient.carbon_content / 100.0
        n_new = ingredient.nitrogen_content / 100.0
        
        denominator = (1 - m_new) * (c_new - target_cn * n_new)
        if denominator == 0:
            return -1.0
            
        w_new = (target_cn * current_nitrogen_kg - current_carbon_kg) / denominator
        return w_new if w_new > 0 else -1.0

    def calculate_required_weight_for_moisture(self, target_moisture: float, current_total_weight: float, current_water_weight: float, ingredient: RecipeIngredient) -> float:
        """
        Calculate the required wet weight of an ingredient to achieve a target moisture.
        """
        m_new = ingredient.moisture_content / 100.0
        target_m = target_moisture / 100.0
        
        denominator = m_new - target_m
        if denominator == 0:
            return -1.0
            
        w_new = (target_m * current_total_weight - current_water_weight) / denominator
        return w_new if w_new > 0 else -1.0

    def evaluate_recipe(self, ingredients: List[RecipeIngredient], available_ingredients: Optional[List[RecipeIngredient]] = None) -> RecipeEvaluation:
        """
        Evaluates a list of ingredients and applies rules to generate suggestions.
        """
        if available_ingredients is None:
            available_ingredients = []

        if not ingredients:
            return RecipeEvaluation(
                total_weight_kg=0.0,
                total_carbon_weight=0.0,
                total_nitrogen_weight=0.0,
                calculated_cn_ratio=0.0,
                calculated_moisture_percent=0.0,
                suggestions=[ExpertSuggestion(
                    issue="Empty Recipe", 
                    recommendation="Please add ingredients to your compost mix to receive an evaluation.", 
                    severity="high"
                )],
                is_optimal=False
            )

        total_weight = 0.0
        total_water_weight = 0.0
        total_carbon_weight = 0.0
        total_nitrogen_weight = 0.0

        # calculate total weights for water, carbon, and nitrogen
        for item in ingredients:
            weight = item.weight_kg
            total_weight += weight
            
            # water weight is straight from moisture percentage
            water_weight = weight * (item.moisture_content / 100.0)
            total_water_weight += water_weight
            
            # dry weight is whatever remains after removing water
            dry_weight = weight - water_weight
            
            # carbon and Nitrogen amounts are based on the dry matter (dry weight)
            carbon_weight = dry_weight * (item.carbon_content / 100.0)
            nitrogen_weight = dry_weight * (item.nitrogen_content / 100.0)
            
            total_carbon_weight += carbon_weight
            total_nitrogen_weight += nitrogen_weight

        # calculate final metrics for the whole system
        system_moisture = (total_water_weight / total_weight) * 100.0 if total_weight > 0 else 0.0
        cn_ratio = (total_carbon_weight / total_nitrogen_weight) if total_nitrogen_weight > 0 else 0.0

        # rule-based logic engine: generating suggestions based on defined optimal ranges
        suggestions = []
        
        # 1. evaluate C/N Ratio
        if cn_ratio < self.min_cn_ratio:
            is_acceptable = cn_ratio >= 15.0
            severity = "medium" if is_acceptable else "high"
            issue_text = f"C/N Ratio is acceptable but low ({cn_ratio:.1f}:1)" if is_acceptable else f"C/N Ratio is too low ({cn_ratio:.1f}:1)"
            recommendation = "Your mix has too much nitrogen. Add more 'browns' (carbon-rich materials)."
            if available_ingredients:
                options = []
                for db_ing in available_ingredients:
                    w = self.calculate_required_weight_for_cn(self.min_cn_ratio, total_carbon_weight, total_nitrogen_weight, db_ing)
                    if w > 0:
                        options.append((db_ing.name, w))
                if options:
                    options.sort(key=lambda x: x[1])  # sort by least amount needed
                    top_3 = options[:3]
                    sug_text = " or ".join([f"{w:.1f} kg of {name}" for name, w in top_3])
                    prefix = "Your C/N ratio is acceptable but could be improved." if is_acceptable else "Your C/N ratio is too low."
                    recommendation = f"{prefix} Add {sug_text} to balance it to the optimal range."
            
            suggestions.append(ExpertSuggestion(
                issue=issue_text,
                recommendation=recommendation,
                severity=severity
            ))
        elif cn_ratio > self.max_cn_ratio:
            is_acceptable = cn_ratio <= 35.0
            severity = "medium" if is_acceptable else "high"
            issue_text = f"C/N Ratio is acceptable but high ({cn_ratio:.1f}:1)" if is_acceptable else f"C/N Ratio is too high ({cn_ratio:.1f}:1)"
            recommendation = "Your mix has too much carbon. Add more 'greens' (nitrogen-rich materials)."
            if available_ingredients:
                options = []
                for db_ing in available_ingredients:
                    w = self.calculate_required_weight_for_cn(self.max_cn_ratio, total_carbon_weight, total_nitrogen_weight, db_ing)
                    if w > 0:
                        options.append((db_ing.name, w))
                if options:
                    options.sort(key=lambda x: x[1])
                    top_3 = options[:3]
                    sug_text = " or ".join([f"{w:.1f} kg of {name}" for name, w in top_3])
                    prefix = "Your C/N ratio is acceptable but could be improved." if is_acceptable else "Your C/N ratio is too high."
                    recommendation = f"{prefix} Add {sug_text} to balance it to the optimal range."

            suggestions.append(ExpertSuggestion(
                issue=issue_text,
                recommendation=recommendation,
                severity=severity
            ))

        # 2. evaluate Moisture Level
        if system_moisture < self.min_moisture:
            recommendation = "Your mix is too dry, which stops the composting process. Mix in more wet ingredients (greens)."
            if available_ingredients:
                options = []
                for db_ing in available_ingredients:
                    w = self.calculate_required_weight_for_moisture(self.min_moisture, total_weight, total_water_weight, db_ing)
                    if w > 0:
                        options.append((db_ing.name, w))
                if options:
                    options.sort(key=lambda x: x[1])
                    top_3 = options[:3]
                    sug_text = " or ".join([f"{w:.1f} kg of {name}" for name, w in top_3])
                    recommendation = f"To raise the moisture to {self.min_moisture}%, I suggest adding: {sug_text}."

            suggestions.append(ExpertSuggestion(
                issue=f"Moisture is too low ({system_moisture:.1f}%)",
                recommendation=recommendation,
                severity="medium"
            ))
        elif system_moisture > self.max_moisture:
            recommendation = "Your mix is too wet, which can cause foul odors. Mix in dry, bulky 'browns'."
            if available_ingredients:
                options = []
                for db_ing in available_ingredients:
                    w = self.calculate_required_weight_for_moisture(self.max_moisture, total_weight, total_water_weight, db_ing)
                    if w > 0:
                        options.append((db_ing.name, w))
                if options:
                    options.sort(key=lambda x: x[1])
                    top_3 = options[:3]
                    sug_text = " or ".join([f"{w:.1f} kg of {name}" for name, w in top_3])
                    recommendation = f"To lower the moisture to {self.max_moisture}%, I suggest adding: {sug_text}."

            suggestions.append(ExpertSuggestion(
                issue=f"Moisture is too high ({system_moisture:.1f}%)",
                recommendation=recommendation,
                severity="medium"
            ))

        # check if recipe is optimal (no suggestions means it's within all optimal ranges)
        is_optimal = len(suggestions) == 0

        if is_optimal:
            suggestions.append(ExpertSuggestion(
                issue="Optimal Recipe",
                recommendation="Your compost mix looks great! Both the C/N ratio and moisture levels are perfectly balanced to start the composting process.",
                severity="low"
            ))

        return RecipeEvaluation(
            total_weight_kg=total_weight,
            total_carbon_weight=total_carbon_weight,
            total_nitrogen_weight=total_nitrogen_weight,
            calculated_cn_ratio=cn_ratio,
            calculated_moisture_percent=system_moisture,
            suggestions=suggestions,
            is_optimal=is_optimal
        )

# simple test case to demonstrate functionality
if __name__ == "__main__":
    expert_system = CompostExpertSystem()

    # simulation of database available ingredients for testing
    available_db = [
        RecipeIngredient(name="Corn stalks", weight_kg=0.0, moisture_content=12.00, nitrogen_content=0.62, carbon_content=40.66),
        RecipeIngredient(name="Grass clippings", weight_kg=0.0, moisture_content=82.00, nitrogen_content=3.40, carbon_content=40.00),
        RecipeIngredient(name="Cocoa shells", weight_kg=0.0, moisture_content=8.00, nitrogen_content=2.00, carbon_content=52.00),
        RecipeIngredient(name="Coffee grounds", weight_kg=0.0, moisture_content=60.00, nitrogen_content=2.00, carbon_content=40.00),
    ]

    # FIRST EVALUATION: Only Apple processing sludge (high moisture, low C/N)
    test_recipe1 = [
        RecipeIngredient(
            name="Apple processing sludge", 
            weight_kg=10.00, 
            moisture_content=59.00, 
            nitrogen_content=1.15, 
            carbon_content=8.04
        )
    ]
    
    evaluation1 = expert_system.evaluate_recipe(test_recipe1, available_ingredients=available_db)
    print("\n1 - First Compost Recipe Evaluation:")
    print(f"Total Weight: {evaluation1.total_weight_kg:.2f} kg")
    print(f"Calculated C/N: {evaluation1.calculated_cn_ratio:.2f}")
    print(f"Calculated Moisture: {evaluation1.calculated_moisture_percent:.2f}%\n")
    
    for s in evaluation1.suggestions:
        print(f"[{s.severity.upper()}] {s.issue}: {s.recommendation}")

    # SECOND EVALUATION: Adding Corn stalks (low moisture, high C/N) to balance the recipe
    test_recipe2 = [
        RecipeIngredient(
            name="Apple processing sludge", 
            weight_kg=10.00, 
            moisture_content=59.00, 
            nitrogen_content=1.15, 
            carbon_content=8.04
        ),
        RecipeIngredient(
            name="Corn stalks", 
            weight_kg=4.00, 
            moisture_content=12.00, 
            nitrogen_content=0.62, 
            carbon_content=40.66 
        )
    ]
    
    evaluation2 = expert_system.evaluate_recipe(test_recipe2, available_ingredients=available_db)
    print("\n2 - Second Compost Recipe Evaluation:")
    print(f"Total Weight: {evaluation2.total_weight_kg:.2f} kg")
    print(f"Calculated C/N: {evaluation2.calculated_cn_ratio:.2f}")
    print(f"Calculated Moisture: {evaluation2.calculated_moisture_percent:.2f}%\n")
    
    for s in evaluation2.suggestions:
        print(f"[{s.severity.upper()}] {s.issue}: {s.recommendation}")