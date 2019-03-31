suite = matlab.unittest.TestSuite.fromFile('GazePointDataCorrectorTest.m');
suite(end).run

%% 
testImDisp = ImageDisplacerTest;
result = run(testImDisp);


