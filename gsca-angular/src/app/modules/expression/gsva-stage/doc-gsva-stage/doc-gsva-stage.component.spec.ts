import { async, ComponentFixture, TestBed } from '@angular/core/testing';

import { DocGsvaStageComponent } from './doc-gsva-stage.component';

describe('DocGsvaStageComponent', () => {
  let component: DocGsvaStageComponent;
  let fixture: ComponentFixture<DocGsvaStageComponent>;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [ DocGsvaStageComponent ]
    })
    .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(DocGsvaStageComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
