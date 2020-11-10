import { HttpClient } from '@angular/common/http';
import { Injectable } from '@angular/core';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { BaseHttpService } from 'src/app/shared/base-http.service';
import { DegTableRecord } from 'src/app/shared/model/degtablerecord';
import { ExprSearch } from 'src/app/shared/model/exprsearch';

@Injectable({
  providedIn: 'root',
})
export class ExpressionApiService extends BaseHttpService {
  constructor(http: HttpClient) {
    super(http);
  }

  public getDEGTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/deg/degtable', postTerm);
  }
  public getDEGPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/deg/degplot', postTerm);
  }
  public getDEGSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/deg/degplot/single/gene', postTerm);
  }
  public getDEGSingleCancerTypePlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/deg/degplot/single/cancertype', postTerm);
  }
  public getSurvivalTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/survival/survivaltable', postTerm);
  }
  public getSurvivalPlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/survival/survivalplot', postTerm);
  }
  public getSurvivalSingleGenePlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/survival/single/gene', postTerm);
  }
  public getSubtypeTable(postTerm: ExprSearch): Observable<any> {
    return this.postData('expression/subtype/subtypetable', postTerm);
  }
  public getSubtypePlot(postTerm: ExprSearch): Observable<any> {
    return this.postDataImage('expression/subtype/subtypeplot', postTerm);
  }
}
