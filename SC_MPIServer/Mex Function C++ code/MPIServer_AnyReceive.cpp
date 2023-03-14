#include "mex.hpp"
#include "mexAdapter.hpp"

using namespace matlab::data;
using matlab::mex::ArgumentList;

extern "C"
{
    void MPIServer_AnyReceive(int *iT, float *msg, bool *flag, int *ierror);
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
        int iT;
        bool flag;
        
        TypedArray<float> inputArr = inputs[0];
        buffer_ptr_t<float> bPtr = inputArr.release();
        float * ptr = bPtr.get();

        // calling mpiserver AnyReceive from fortran
        //MPIServer_AnyReceive(&iT, ptr, &flag, &ierror); //&=search in other files, ptr is created in this file

        if (ierror != 0)
        {
            stream << "An error occured in MPIServer_AnyReceive\n";
            displayOnMATLAB(stream);
        }

        // the outputs of the function, these are the outputs the mexx function should have
        outputs[0] = factory.createScalar(iT);
        outputs[1] = factory.createArrayFromBuffer<float>(inputArr.getDimensions(), std::move(bPtr));
        outputs[2] = factory.createScalar(flag);
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