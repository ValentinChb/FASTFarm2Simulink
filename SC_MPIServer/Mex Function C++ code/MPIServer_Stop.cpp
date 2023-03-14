#include "mex.hpp"
#include "mexAdapter.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;

extern "C"
{
    void MPIServer_Stop(int *ierror);
}

class MexFunction : public matlab::mex::Function
{
    std::shared_ptr<matlab::engine::MATLABEngine> matlabPtr = getEngine();
    ArrayFactory factory;
    std::ostringstream stream;

public:
    void operator()(ArgumentList outputs, ArgumentList inputs)
    {
        // fortran output variables
        int ierror;

        // formatting matlab input as fortran input


        // calling mpiserver stop from fortran
        MPIServer_Stop(&ierror);

        if (ierror != 0)
        {
            stream << "An error occured in MPIServer_Stop\n";
            displayOnMATLAB(stream);
        }

        // outputs
        
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