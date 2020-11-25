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

  public getSnvTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snv/snvtable', postTerm);
  }
  public getSnvPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvplot', postTerm);
  }
  public getSnvLollipop(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/lollipop', postTerm);
  }
  public getSnvSummary(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvsummary', postTerm);
  }
  public getSnvOncoplot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvoncoplot', postTerm);
  }
  public getSnvTitv(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snv/snvtitv', postTerm);
  }
  public getSnvSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvsurvivaltable', postTerm);
  }
  public getSnvSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snvsurvival/snvsurvivalplot', postTerm);
  }
  public getSnvSurvivalSingleGene(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snvsurvival/snvsurvivalsinglegeneplot', postTerm);
  }
  public getSnvGenesetSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/snvsurvival/snvgenesetsurvivaltable', postTerm);
  }
  public getSnvGenesetSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snvsurvival/snvgenesetsurvivalplot', postTerm);
  }
  public getSnvGenesetSurvivalSingleCancer(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/snvsurvival/snvgenesetsurvivalsinglecancer', postTerm);
  }
  public getMethyDeTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('mutation/methylation/methylationdetable', postTerm);
  }
  public getMethyDePlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/methylation/methylationdeplot', postTerm);
  }
  public getSingleMethyDE(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('mutation/methylation/methylationsinglegenedeplot', postTerm);
  }
}
