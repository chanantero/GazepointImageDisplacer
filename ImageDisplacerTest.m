classdef ImageDisplacerTest < matlab.unittest.TestCase
    
    properties
    end
    
    methods(Test)
        function test_fit_rectangle_into_itself_should_return_itself(testCase)
            fitted_rect = ImageDisplacer.fitRectangleIntoAnother([0 0; 1 2], [0 0; 1 2]);
            testCase.assertEqual([0 0; 1 2], fitted_rect);
        end
    end
end

