import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocCnvGenesetSurvivalComponent } from './doc-cnv-geneset-survival.component';

describe('DocCnvGenesetSurvivalComponent', () => {
  let component: DocCnvGenesetSurvivalComponent;
  let fixture: ComponentFixture<DocCnvGenesetSurvivalComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocCnvGenesetSurvivalComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocCnvGenesetSurvivalComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
