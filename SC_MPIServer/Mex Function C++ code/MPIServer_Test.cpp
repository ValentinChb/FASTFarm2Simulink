#include "mex.hpp"
#include "mexAdapter.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;

extern "C"
{
    void MPIServer_Test();
}

class MexFunction : public matlab::mex::Function
{
    std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
    ArrayFactory factory;
    std::ostringstream stream;

public:
    void operator()(ArgumentList outputs, ArgumentList inputs)
    {
        // calling mpiserver test
        MPIServer_Test();
        stream << "Mex function test called successfully\n";
    }

    void displayOnMATLAB(std::ostringstream &stream)
    {
        // Pass stream content to MATLAB fprintf function
        matlabPtr->feval(u"fprintf", 0,
                         std::vector<Array>({factory.createScalar(stream.str())}));
        // Clear stream buffer
        stream.str("");
    }
};