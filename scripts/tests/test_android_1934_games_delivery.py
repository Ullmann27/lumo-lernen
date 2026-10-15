import copy
import importlib.util
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
spec = importlib.util.spec_from_file_location('package1934', ROOT/'tools/package_android_test_delivery.py')
package = importlib.util.module_from_spec(spec)
spec.loader.exec_module(package)


class GameDeliveryGuardTest(unittest.TestCase):
    def setUp(self):
        self.source, self.godot = 'a'*40, 'b'*40
        self.proof = {'status':'PASS', 'candidate_source': self.source,
            'godot_revision':self.godot, 'profiles_unchanged':True,
            'wallet_unchanged':True, 'restart_unchanged':True,
            'dice':{'real_roll_pause_resume':True},
            'fold_driver':{'native_process_retained':True},
            'saved_setup':{'driver':'fox','kart':'gecko_velo','track':'zauberwald'},
            'kart_scroll':{'movement_pixels':100}, 'track_scroll':{'movement_pixels':110}}

    def verify(self):
        package.validate_games(self.proof, source=self.source, godot_revision=self.godot)

    def test_matching_observed_inputs_and_actual_saved_setup_pass(self):
        self.verify()

    def test_unverified_source_profile_wallet_restart_or_failed_run_rejected(self):
        original=copy.deepcopy(self.proof)
        for key,value in [('status','FAIL'),('candidate_source','c'*40),
                          ('godot_revision','c'*40),('profiles_unchanged',False),
                          ('wallet_unchanged',False),('restart_unchanged',False)]:
            self.proof={**original,key:value}
            with self.subTest(key=key),self.assertRaises(ValueError):self.verify()

    def test_static_caption_and_incorrect_actual_save_rejected(self):
        for name in ['kart_scroll','track_scroll']:
            self.proof[name]['movement_pixels']=0
            with self.assertRaises(ValueError):self.verify()
            self.proof[name]['movement_pixels']=100
        for key in ['driver','kart','track']:
            old=self.proof['saved_setup'][key]
            self.proof['saved_setup'][key]='other'
            with self.assertRaises(ValueError):self.verify()
            self.proof['saved_setup'][key]=old

    def test_missing_actual_pause_or_live_process_retention_rejected(self):
        self.proof['dice']['real_roll_pause_resume']=False
        with self.assertRaises(ValueError):self.verify()
        self.proof['dice']['real_roll_pause_resume']=True
        self.proof['fold_driver']['native_process_retained']=False
        with self.assertRaises(ValueError):self.verify()


if __name__=='__main__':unittest.main()
