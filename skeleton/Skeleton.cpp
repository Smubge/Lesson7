#include "llvm/Pass.h"
#include "llvm/IR/Module.h"
#include "llvm/Passes/PassBuilder.h"
#include "llvm/Passes/PassPlugin.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/Transforms/Utils/Local.h"
using namespace llvm;

namespace {

struct SkeletonPass : public PassInfoMixin<SkeletonPass> {
    PreservedAnalyses run(Module &M, ModuleAnalysisManager &AM) {
        DenseMap<Value*, ConstantInt*> knownConstants;
        bool changed = false;
        for (auto &F : M) {
            for (auto &BB : F) {
                for (auto &I : make_early_inc_range(BB)) { //Need to avoid corrupted pointers??? because for some reason that exists... wow this caused me 1 hour of confusing error messages and scrolling through documentation 
                    if (auto* store = dyn_cast<StoreInst>(&I)) { //store instr
                        if (auto *C = dyn_cast<ConstantInt>(store->getValueOperand())) {
                            knownConstants[store->getPointerOperand()] = C;
                            changed = true;
                            store->eraseFromParent();
                        }
                    }
                    else if (auto* load = dyn_cast<LoadInst>(&I)) { //load instr
                        if (knownConstants.count(load->getPointerOperand())) {
                            ConstantInt* C = knownConstants[load->getPointerOperand()];
                            load->replaceAllUsesWith(C);
                            load->eraseFromParent();
                            changed = true;
                        }
                    } 
                    if (auto* op = dyn_cast<BinaryOperator>(&I)) { //binary operations
                        if (auto *C1 = dyn_cast<ConstantInt>(op->getOperand(0))) {
                            if (auto *C2 = dyn_cast<ConstantInt>(op->getOperand(1))) {
                                Constant *result = nullptr;
                                switch (op->getOpcode()) { //why was this so much easier than store and load :(
                                    case Instruction::Add: //addition
                                        result = ConstantInt::get(op->getType(), C1->getValue() + C2->getValue());
                                        break;
                                    case Instruction::Sub: //subtraction
                                        result = ConstantInt::get(op->getType(), C1->getValue() - C2->getValue());
                                        break;
                                    case Instruction::Mul: //multiplication
                                        result = ConstantInt::get(op->getType(), C1->getValue() * C2->getValue());
                                        break;
                                    case Instruction::UDiv: //unsigned division
                                        if (!C2->isZero())
                                            result = ConstantInt::get(op->getType(), C1->getValue().udiv(C2->getValue()));
                                        break;
                                    case Instruction::SDiv: //signed division
                                        if (!C2->isZero())
                                            result = ConstantInt::get(op->getType(), C1->getValue().sdiv(C2->getValue()));
                                        break;
                                    default: //TODO: check for more binary operations??
                                        break;
                                }
                                if (result) {
                                    op->replaceAllUsesWith(result);
                                    op->eraseFromParent();
                                    changed = true;
                                }
                            }
                        }
                    }
                }
            }
        }
        //pass that does dead code elimnation TODO: might be redundant please check lol  
        for (auto &F : M) {
            for (auto &BB : F) {
                for (auto &I : make_early_inc_range(BB)) {
                    if (I.use_empty() && !I.mayHaveSideEffects() && isInstructionTriviallyDead(&I)) {
                        I.eraseFromParent();
                        changed = true;
                    } 
                }
            }
        }
        return changed ? PreservedAnalyses::none() : PreservedAnalyses::all(); 
    };
};

}
//None if changed ,all if just observing code for PreservedAnalyses, remember
extern "C" LLVM_ATTRIBUTE_WEAK ::llvm::PassPluginLibraryInfo
llvmGetPassPluginInfo() {
    return {
        .APIVersion = LLVM_PLUGIN_API_VERSION,
        .PluginName = "Skeleton pass",
        .PluginVersion = "v0.1",
        .RegisterPassBuilderCallbacks = [](PassBuilder &PB) {
            PB.registerPipelineStartEPCallback(
                [](ModulePassManager &MPM, OptimizationLevel Level) {
                    MPM.addPass(SkeletonPass());
                });
        }
    };
}

