import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location(
    "english_v2", Path(__file__).parents[1] / "build_english_dictionary_v2.py")
builder = importlib.util.module_from_spec(spec)
spec.loader.exec_module(builder)


class EnglishDictionaryV2Test(unittest.TestCase):
    def test_simple_definitions_do_not_give_away_the_answer(self):
        self.assertEqual(builder.clean_definition("apple", "An apple is a sweet fruit."), "A sweet fruit.")
        self.assertEqual(builder.clean_definition("home", "Where a person lives. This can be a house."), "Where a person lives.")
        self.assertEqual(builder.clean_definition("happy", "When you feel happy, you feel good."), "Good.")
        self.assertEqual(builder.clean_definition("miss", "If you miss something, you don't hit it."), "To not hit something.")

    def test_holds_unsafe_reference_and_obscure_senses(self):
        for text, tags in [("The third-person singular form of father.", []),
                           ("A sexual act.", []), ("An old piece of cloth.", ["archaic"]),
                           ("A chair is a seat.", []), ("The act of collapsing.", [])]:
            self.assertIsNotNone(builder.sense_problem("chair", {"gloss": text, "tags": tags}, text, 160))
        self.assertIsNone(builder.sense_problem("rain", {"gloss": "Water falling from clouds.", "tags": []}, "Water falling from clouds.", 160))

    def test_frequency_and_exclusions_are_fail_closed(self):
        policy = {"minimumZipf": 4, "minimumAnswerZipf": 4.5, "maximumDefinitionCharacters": 160,
                  "familiarExceptions": [], "excludedWords": ["votary"], "definitionOverrides": {}}
        source = {"rawSha256": "test", "entries": [
            {"word": word, "zipf": frequency, "senses": [{"pos": "noun", "senseIndex": 0,
                "gloss": "A useful object for everyday tasks.", "tags": []}]}
            for word, frequency in [("table", 5), ("bathos", 2), ("votary", 5)]]}
        entries, _ = builder.build(source, policy)
        self.assertEqual([e["id"] for e in entries], ["en_v2_table"])
        self.assertEqual(entries[0]["reviewStatus"], "machineChecked")
        self.assertIn("CC BY-SA 4.0", entries[0]["sources"][0])
        self.assertEqual(entries[0]["evidence"]["sourceGloss"], "A useful object for everyday tasks.")

    def test_source_changed_exception_cannot_be_applied(self):
        policy = {"minimumZipf": 4, "minimumAnswerZipf": 4.5, "maximumDefinitionCharacters": 160,
                  "familiarExceptions": [], "excludedWords": [],
                  "definitionOverrides": {"book": {"sourceGloss": "old gloss", "definition": "New text"}}}
        source = {"rawSha256": "test", "entries": [{"word": "book", "zipf": 5, "senses": [
            {"pos": "noun", "senseIndex": 0, "gloss": "different gloss", "tags": []}]}]}
        with self.assertRaisesRegex(ValueError, "Stale"):
            builder.build(source, policy)

    def test_lookup_frequency_does_not_automatically_make_an_answer(self):
        policy = {"minimumZipf": 4, "minimumAnswerZipf": 4.5,
                  "maximumDefinitionCharacters": 160,
                  "familiarExceptions": ["elephant"], "excludedWords": [], "definitionOverrides": {}}
        source = {"rawSha256": "test", "entries": [
            {"word": word, "zipf": frequency, "senses": [{"pos": "noun", "senseIndex": 0,
                "gloss": "A useful object for everyday tasks.", "tags": []}]}
            for word, frequency in [("spare", 4.3), ("table", 5), ("elephant", 3.5)]]}
        entries, report = builder.build(source, policy)
        by_word = {entry["latin"]: entry for entry in entries}
        self.assertTrue(by_word["SPARE"]["acceptedGuess"])
        self.assertFalse(by_word["SPARE"]["solutionEligible"])
        self.assertTrue(by_word["TABLE"]["solutionEligible"])
        self.assertTrue(by_word["ELEPHANT"]["solutionEligible"])
        self.assertEqual(report["answers"], 2)

    def test_child_familiarity_hold_wins_over_frequency_and_familiar_exception(self):
        policy = {"minimumZipf": 4, "minimumAnswerZipf": 4.5,
                  "maximumDefinitionCharacters": 160,
                  "familiarExceptions": ["finance"], "excludedWords": [], "definitionOverrides": {},
                  "answerHolds": {"adult_business_and_bureaucracy": ["corporation", "finance", "research"]}}
        source = {"rawSha256": "test", "entries": [
            {"word": word, "zipf": 5.5, "senses": [{"pos": "noun", "senseIndex": 0,
                "gloss": "A useful object for everyday tasks.", "tags": []}]}
            for word in ["corporation", "finance", "research", "book"]]}
        entries, report = builder.build(source, policy)
        for entry in entries:
            self.assertTrue(entry["acceptedGuess"])
            self.assertEqual(entry["solutionEligible"], entry["latin"] == "BOOK")
            self.assertEqual(entry["reviewStatus"], "machineChecked")
            self.assertIn("sourceGloss", entry["evidence"])
        self.assertEqual(report["answers"], 1)
        self.assertEqual(report["answerHoldCounts"]["adult_business_and_bureaucracy"], 3)

    def test_vandalized_obfuscated_source_is_held_from_lookup_too(self):
        text = "A statement that tells whether you might get spanked for master baiting in class."
        self.assertEqual(builder.sense_problem("rule", {"gloss": text, "tags": []}, text, 160), "sensitive_word_or_sense")
        self.assertIsNotNone(builder.sense_problem("rule", {"gloss": "master-baiting", "tags": []}, "An otherwise ordinary statement.", 160))

    def test_rejected_ordinary_sense_does_not_fall_back_to_obscure_noun(self):
        policy = {"minimumZipf": 4, "minimumAnswerZipf": 4.5, "maximumDefinitionCharacters": 160,
                  "familiarExceptions": [], "excludedWords": [], "definitionOverrides": {}}
        source = {"rawSha256": "test", "entries": [{"word": "familiar", "zipf": 4.61, "senses": [
            {"pos": "adj", "senseIndex": 0, "gloss": "If something is familiar, you already know it.", "tags": []},
            {"pos": "noun", "senseIndex": 0, "gloss": "A familiar is the magical pet of a witch.", "tags": []}]}]}
        entries, report = builder.build(source, policy)
        self.assertEqual(entries, [])
        self.assertEqual(report["counts"]["held"], 1)

    def test_source_maintenance_messages_and_vague_definitions_are_held(self):
        for text in [": This short section needs someone to add to it.", "A something that looks like something else.", "A fruit.", "Another word for hate."]:
            self.assertIsNotNone(builder.sense_problem("test", {"gloss": text, "tags": []}, text, 160))


if __name__ == "__main__":
    unittest.main()
