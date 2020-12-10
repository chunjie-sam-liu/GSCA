import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { ExprSearch } from 'src/app/shared/model/exprsearch';
@Injectable({
  providedIn: 'root',
})
export class MutationApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  public getResourcePlotBlob(uuidname: string, plotType = 'png'): Observable<any> {
    return this.getData('resource/responseplot/' + uuidname + '.' + plotType);
  }
  public getResourcePlotURL(uuidname: string, plotType = 'pdf'): string {
    return this.generateRoute('resource/responseplot/' + uuidname + '.' + plotType);
  }
  public getSnvTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snv/snvtable', postTerm);
  }
  public getSnvPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snv/snvplot', postTerm);
  }
  public getSnvLollipop(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snv/lollipop', postTerm);
  }
  public getSnvSummary(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snv/snvsummary', postTerm);
  }
  /*
  public getSnvSummary(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvsummary', postTerm);
  }
  public getSnvOncoplot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvoncoplot', postTerm);
  }
  public getSnvTitv(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvtitv', postTerm);
  }
  */
  public getSnvSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvsurvivaltable', postTerm);
  }
  public getSnvSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvsurvivalplot', postTerm);
  }
  public getSnvSurvivalSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvsurvivalsinglegeneplot', postTerm);
  }
  public getSnvGenesetSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvgenesetsurvivaltable', postTerm);
  }
  public getSnvGenesetSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvgenesetsurvivalplot', postTerm);
  }
  public getSnvGenesetSurvivalSingleCancer(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvgenesetsurvivalsinglecancer', postTerm);
  }
  public getMethyDeTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methylation/methylationdetable', postTerm);
  }
  public getMethyDePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methylation/methylationdeplot', postTerm);
  }
  public getSingleGeneMethyDE(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methylation/singlegenemethyde', postTerm);
  }
  public getSingleCancerMethyDE(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methylation/singlecancermethyde', postTerm);
  }
  public getMethySurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methysurvival/methysurvivaltable', postTerm);
  }
  public getMethySurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methysurvival/methysurvivalplot', postTerm);
  }
  public getMethySurvivalSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methysurvival/methysurvivalsinglegene', postTerm);
  }
  public getMethyCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methycor/methycortable', postTerm);
  }
  public getMethyCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methycor/methycorplot', postTerm);
  }
  public getMethyCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methycor/methycorsinglegene', postTerm);
  }
  public getCnvTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnv/cnvtable', postTerm);
  }
  public getCnvPiePlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnv/cnvpieplot', postTerm);
  }
  public getCnvHetePointImage(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnv/cnvhetepointplot', postTerm);
  }
  public getCnvHomoPointImage(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnv/cnvhomopointplot', postTerm);
  }
  public getCnvSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnv/cnvsinglegene', postTerm);
  }
  public getCnvCorTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvcor/cnvcortable', postTerm);
  }
  public getCnvCorPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvcor/cnvcorplot', postTerm);
  }
  public getCnvCorSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvcor/cnvcorsinglegene', postTerm);
  }
  public getCnvSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvsurvivaltable', postTerm);
  }
  public getCnvSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvsurvivalplot', postTerm);
  }
  public getCnvGenesetSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvgenesetsurvivalplot', postTerm);
  }
  public getCnvGenesetSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvgenesetsurvivaltable', postTerm);
  }
  public getCnvSurvivalSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvsurvivalsinglegeneplot', postTerm);
  }
  public getCnvGenesetSurvivalSingleCancer(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/cnvsurvival/cnvgenesetsurvivalsinglecancer', postTerm);
  }
}
